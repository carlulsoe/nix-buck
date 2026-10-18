"""Store path helpers shared by the relocator and publish: Nix's base-32
and reference scanning."""

import os
import re

STORE = "/nix/store/"
NIX32 = "0123456789abcdfghijklmnpqrsvwxyz"


def nix32(data: bytes) -> str:
    """Nix's base-32 encoding (printHash32)."""
    out = []
    for n in range((len(data) * 8 - 1) // 5, -1, -1):
        b = n * 5
        i, j = b // 8, b % 8
        c = data[i] >> j
        if i + 1 < len(data):
            c |= data[i + 1] << (8 - j)
        out.append(NIX32[c & 0x1F])
    return "".join(out)


def scan(root, candidates):
    """The basenames in `candidates` whose hash part occurs under root, in a
    file, a symlink target or an entry name: references, found the way Nix
    finds them in a NAR."""
    if not candidates:
        return set()
    by_hash = {c[:32].encode(): c for c in candidates}
    pattern = re.compile(b"|".join(re.escape(h) for h in by_hash))
    found = set()

    def look(path):
        if os.path.islink(path):
            data = os.readlink(path).encode()
        else:
            with open(path, "rb") as f:
                data = f.read()
        found.update(by_hash[m.group()] for m in pattern.finditer(data))

    if not os.path.isdir(root) or os.path.islink(root):
        look(root)
    for dirpath, dirs, files in os.walk(root):
        for name in dirs + files:
            path = os.path.join(dirpath, name)
            found.update(by_hash[m.group()] for m in pattern.finditer(name.encode()))
            if os.path.islink(path) or name in files:
                look(path)
    return found
