"""Store path helpers shared by the relocator, push-closure, publish and the
substituter: Nix's base-32, reference scanning, and the substituter's index.

The index is a directory with one <hashpart>.json per store path the
substituter serves: {"path", "digest" (REAPI Directory digest of its
contents), "references" (basenames)}.
"""

import json
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
    """The basenames in `candidates` whose hash part occurs in a file or
    symlink target under root: references, found the way Nix finds them."""
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
            if os.path.islink(path) or name in files:
                look(path)
    return found


def index_entry(index, hashpart):
    if not re.fullmatch(f"[{NIX32}]{{32}}", hashpart):
        return None
    try:
        with open(os.path.join(index, hashpart + ".json")) as f:
            entry = json.load(f)
    except FileNotFoundError:
        return None
    if not os.path.basename(entry["path"]).startswith(hashpart + "-"):
        raise ValueError(f"index entry {hashpart} names {entry['path']}")
    return entry


def add_to_index(index, path, digest, references):
    """Index a store path. A path already indexed with different contents is
    an error: one store path, one content."""
    hashpart = os.path.basename(path)[:32]
    entry = {"path": path, "digest": digest, "references": sorted(references)}
    old = index_entry(index, hashpart)
    if old and old != entry:
        raise SystemExit(f"{path} is already indexed with other contents:\n  {old}\n  {entry}")
    os.makedirs(index, exist_ok=True)
    with open(os.path.join(index, hashpart + ".json"), "w") as f:
        json.dump(entry, f, indent=2)
