"""Fail if a relocated closure still depends on where it sits, or still
names a store path it was relocated from.

Checks the three strings that pin a nixpkgs output to /nix/store: PT_INTERP,
RUNPATH and symlinks. Each must be relative and resolve inside the tree.
Other embedded "/nix/store/" strings (spec strings, configure-time defaults)
are counted and listed but do not fail the check: they do not stop a binary
from loading, and they name relocated paths. No original hash may remain.

usage: check-relocatable.py TREE ATTRS_JSON
  TREE contains nix/store/; ATTRS_JSON is the relocating build's structured
  attrs, whose "closure" lists the originals.
"""

import json
import os
import subprocess
import sys

from storepath import scan

STORE = b"/nix/store/"


def elf_kind(path):
    with open(path, "rb") as f:
        head = f.read(18)
    if len(head) < 18 or head[:4] != b"\x7fELF":
        return None
    return int.from_bytes(head[16:18], "little")


def patchelf(flag, path):
    r = subprocess.run(["patchelf", flag, path], capture_output=True, text=True)
    return r.stdout.strip() if r.returncode == 0 else ""


def main(tree, attrs_file):
    tree = os.path.realpath(tree)
    errors, residual = [], []
    elves = 0

    def inside(p):
        return os.path.realpath(p).startswith(tree + os.sep)

    def resolve_origin(entry, file_dir, what, path):
        if not entry.startswith("$ORIGIN/"):
            errors.append(f"{path}: {what} not $ORIGIN-relative: {entry}")
            return
        target = os.path.join(file_dir, entry[len("$ORIGIN/"):])
        if not inside(target) or not os.path.exists(target):
            errors.append(f"{path}: {what} does not resolve inside the tree: {entry}")

    for dirpath, dirs, files in os.walk(tree):
        for name in dirs + files:
            path = os.path.join(dirpath, name)
            rel = os.path.relpath(path, tree)
            if os.path.islink(path):
                target = os.readlink(path)
                if os.path.isabs(target):
                    errors.append(f"{rel}: absolute symlink -> {target}")
                elif not inside(path) and os.path.exists(path):
                    errors.append(f"{rel}: symlink escapes the tree -> {target}")
                continue
            if name not in files:
                continue
            with open(path, "rb") as f:
                data = f.read()
            if data.startswith(b"/* GNU ld script") and STORE in data:
                errors.append(f"{rel}: ld script names an absolute store path")
            elif STORE in data:
                residual.append(rel)
            if elf_kind(path) not in (2, 3):
                continue
            elves += 1
            interp = patchelf("--print-interpreter", path)
            if interp:
                resolve_origin(interp, dirpath, "PT_INTERP", rel)
            for entry in filter(None, patchelf("--print-rpath", path).split(":")):
                if entry.startswith("/"):
                    errors.append(f"{rel}: absolute RUNPATH entry {entry}")
                elif entry == "$ORIGIN" or entry.startswith("$ORIGIN/"):
                    # Nonexistent RUNPATH directories are harmless; escaping is not.
                    if not inside(os.path.join(dirpath, entry[len("$ORIGIN/"):], "x")):
                        errors.append(f"{rel}: RUNPATH escapes the tree: {entry}")
                else:
                    errors.append(f"{rel}: RUNPATH entry not $ORIGIN-relative: {entry}")

    with open(attrs_file) as f:
        originals = [os.path.basename(p["path"]) for p in json.load(f)["closure"]]
    for leaked in sorted(scan(os.path.join(tree, "nix", "store"), originals)):
        errors.append(f"an original store path is still named: {leaked}")

    print(f"checked {elves} ELF images under {tree}")
    print(f"{len(residual)} files still embed a /nix/store string (informational):")
    for r in residual:
        print(f"  {r}")
    if errors:
        print(f"{len(errors)} relocation errors:", file=sys.stderr)
        for e in errors:
            print(f"  {e}", file=sys.stderr)
        sys.exit(1)
    print("relocatable: ok")


if __name__ == "__main__":
    main(*sys.argv[1:])
