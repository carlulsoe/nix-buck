"""Copy store paths into <out>/nix/store and rewrite them to be location-independent.

Absolute /nix/store references in RUNPATH, PT_INTERP and symlinks become
$ORIGIN-relative (or plain relative for symlinks); GNU ld scripts that name
siblings in their own directory are reduced to bare file names so ld finds
them on the -L search path. Store path basenames are kept, so the hash stays
in every string.

usage: relocate.py OUT STOREPATH...
"""

import os
import shutil
import subprocess
import sys

STORE = "/nix/store/"


def store_root(path):
    """'/nix/store/abc-x/lib/foo' -> 'abc-x'."""
    return path[len(STORE):].split("/", 1)[0]


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
    def __init__(self, out, paths):
        self.out = os.path.abspath(out)
        self.tree = os.path.join(self.out, "nix", "store")
        self.members = {os.path.basename(p) for p in paths}
        self.paths = paths

    def in_tree(self, abs_store_path):
        root = store_root(abs_store_path)
        if root not in self.members:
            raise SystemExit(f"reference outside closure: {abs_store_path}")
        return os.path.join(self.tree, abs_store_path[len(STORE):])

    def origin_relative(self, abs_store_path, file_dir):
        rel = os.path.relpath(self.in_tree(abs_store_path), file_dir)
        return "$ORIGIN/" + rel

    def copy(self):
        os.makedirs(self.tree)
        for p in self.paths:
            dst = os.path.join(self.tree, os.path.basename(p))
            shutil.copytree(p, dst, symlinks=True)
            subprocess.run(["chmod", "-R", "u+w", dst], check=True)

    def relink(self, path):
        target = os.readlink(path)
        if not target.startswith(STORE):
            return
        rel = os.path.relpath(self.in_tree(target), os.path.dirname(path))
        os.unlink(path)
        os.symlink(rel, path)

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
            new = [self.origin_relative(e, file_dir) if e.startswith(STORE) else e
                   for e in entries
                   if not e.startswith(STORE) or store_root(e) in self.members]
            if new != entries:
                subprocess.run(["patchelf", "--set-rpath", ":".join(new), path], check=True)

    def patch_ld_script(self, path):
        with open(path, "rb") as f:
            data = f.read()
        if not data.startswith(b"/* GNU ld script"):
            return
        text = data.decode()
        file_dir = os.path.dirname(path)
        out = []
        for word in text.split(" "):
            if word.startswith(STORE):
                if os.path.dirname(self.in_tree(word)) != file_dir:
                    raise SystemExit(f"{path}: ld script names a file outside its directory: {word}")
                word = os.path.basename(word)
            out.append(word)
        with open(path, "w") as f:
            f.write(" ".join(out))

    def run(self):
        self.copy()
        # os.walk does not descend into symlinked directories but lists them.
        for dirpath, dirs, files in os.walk(self.tree):
            for name in dirs + files:
                path = os.path.join(dirpath, name)
                if os.path.islink(path):
                    self.relink(path)
                elif name in files:
                    self.patch_elf(path)
                    self.patch_ld_script(path)


if __name__ == "__main__":
    Relocator(sys.argv[1], sys.argv[2:]).run()
