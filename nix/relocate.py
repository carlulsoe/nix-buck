"""Relocate a closure into <out>/nix/store, under new store path names.

Every store path becomes nix/store/<h'>-<name>, where h' is derived from its
original basename and a salt naming the relocator (this source and
patchelf). A relocated path depends only on its original, so it gets the
same name and the same bytes in every closure it appears in, and it never
shares a name with the unpatched original. Within the copies:

- PT_INTERP and RUNPATH become $ORIGIN-relative; RUNPATH entries naming a
  store path outside the closure are dead and dropped;
- symlinks into /nix/store become relative;
- GNU ld scripts that name siblings in their own directory get bare names,
  so ld finds them on the -L search path;
- every remaining occurrence of an original hash, in any file or symlink, is
  rewritten to the new hash (same length, as Nix rewrites hashes).

References are then found the way Nix finds them, by scanning for the new
hashes. closure.json records each relocated path's references, and which
path each root role became. Nothing in the output names an original, so the
build has no references: Nix's own scan confirms the rewrite.

usage: relocate.py OUT SALT ATTRS_JSON
  ATTRS_JSON is the build's structured attrs: "roots" (role -> store path)
  and "closure" (exportReferencesGraph of the roots).
"""

import hashlib
import json
import os
import re
import shutil
import subprocess
import sys

from storepath import STORE, nix32, scan


def relocated(salt, base):
    """The relocated basename for an original store path basename."""
    h = nix32(hashlib.sha256(f"nix-origin-relocated:{salt}:{base}".encode()).digest())
    return h[:32] + base[32:]


def elf_kind(path):
    """Return the ELF e_type for linkable images, None for anything else."""
    with open(path, "rb") as f:
        head = f.read(18)
    if len(head) < 18 or head[:4] != b"\x7fELF":
        return None
    return int.from_bytes(head[16:18], "little")


def patchelf(*args):
    return subprocess.run(["patchelf", *args], capture_output=True, text=True)


class Relocator:
    def __init__(self, out, salt, paths):
        self.out = os.path.abspath(out)
        self.tree = os.path.join(self.out, "nix", "store")
        self.paths = paths
        self.rename = {os.path.basename(p): relocated(salt, os.path.basename(p)) for p in paths}
        self.new_hash = {o[:32].encode(): n[:32].encode() for o, n in self.rename.items()}
        self.old_hashes = re.compile(b"|".join(re.escape(h) for h in self.new_hash))

    def rewrite(self, data: bytes) -> bytes:
        return self.old_hashes.sub(lambda m: self.new_hash[m.group()], data)

    def in_tree(self, abs_store_path):
        base, _, rest = abs_store_path[len(STORE):].partition("/")
        if base not in self.rename:
            raise SystemExit(f"reference outside closure: {abs_store_path}")
        return os.path.join(self.tree, self.rename[base], rest)

    def origin_relative(self, abs_store_path, file_dir):
        return "$ORIGIN/" + os.path.relpath(self.in_tree(abs_store_path), file_dir)

    def copy(self):
        os.makedirs(self.tree)
        for p in self.paths:
            dst = os.path.join(self.tree, self.rename[os.path.basename(p)])
            shutil.copytree(p, dst, symlinks=True)
            subprocess.run(["chmod", "-R", "u+w", dst], check=True)

    def relink(self, path):
        target = os.readlink(path)
        if target.startswith(STORE):
            new = os.path.relpath(self.in_tree(target), os.path.dirname(path))
        else:
            new = self.rewrite(target.encode()).decode()
        if new != target:
            os.unlink(path)
            os.symlink(new, path)

    def patch_elf(self, path):
        # ET_EXEC=2, ET_DYN=3; relocatable objects carry no loader paths.
        if elf_kind(path) not in (2, 3):
            return
        file_dir = os.path.dirname(path)
        interp = patchelf("--print-interpreter", path)
        if interp.returncode == 0 and interp.stdout.strip().startswith(STORE):
            new = self.origin_relative(interp.stdout.strip(), file_dir)
            subprocess.run(["patchelf", "--set-interpreter", new, path], check=True)
        rpath = patchelf("--print-rpath", path)
        if rpath.returncode == 0 and rpath.stdout.strip():
            entries = rpath.stdout.strip().split(":")
            # A store entry outside the closure is dead (e.g. a nuked
            # /nix/store/eeee... reference): the reference scanner would
            # otherwise have pulled it in. Drop it.
            live = [e for e in entries
                    if not e.startswith(STORE) or e[len(STORE):].split("/")[0] in self.rename]
            new = [self.origin_relative(e, file_dir) if e.startswith(STORE) else e for e in live]
            if new != entries:
                subprocess.run(["patchelf", "--set-rpath", ":".join(new), path], check=True)

    def patch_ld_script(self, path):
        with open(path, "rb") as f:
            data = f.read()
        if not data.startswith(b"/* GNU ld script"):
            return
        file_dir = os.path.dirname(path)
        out = []
        for word in data.decode().split(" "):
            if word.startswith(STORE):
                if os.path.dirname(self.in_tree(word)) != file_dir:
                    raise SystemExit(f"{path}: ld script names a file outside its directory: {word}")
                word = os.path.basename(word)
            out.append(word)
        with open(path, "w") as f:
            f.write(" ".join(out))

    def rewrite_file(self, path):
        with open(path, "rb") as f:
            data = f.read()
        new = self.rewrite(data)
        if new != data:
            with open(path, "wb") as f:
                f.write(new)

    def run(self):
        self.copy()
        # os.walk does not descend into symlinked directories but lists them.
        for dirpath, dirs, files in os.walk(self.tree):
            for name in dirs + files:
                path = os.path.join(dirpath, name)
                if self.old_hashes.search(name.encode()):
                    raise SystemExit(f"{path}: an original hash in a file name is not relocated")
                if os.path.islink(path):
                    self.relink(path)
                elif name in files:
                    self.patch_elf(path)
                    self.patch_ld_script(path)
                    self.rewrite_file(path)
        names = set(self.rename.values())
        return {new: sorted(scan(os.path.join(self.tree, new), names)) for new in sorted(names)}


def main(out, salt, attrs_file):
    with open(attrs_file) as f:
        attrs = json.load(f)
    relocator = Relocator(out, salt, sorted(p["path"] for p in attrs["closure"]))
    references = relocator.run()
    roots = {role: relocator.rename[os.path.basename(p)] for role, p in attrs["roots"].items()}
    with open(os.path.join(out, "closure.json"), "w") as f:
        json.dump({"roots": roots, "references": references}, f, indent=2, sort_keys=True)


if __name__ == "__main__":
    main(*sys.argv[1:])
