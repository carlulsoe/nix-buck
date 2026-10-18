"""Publish buck2 outputs as Nix store paths.

For each target: build it and its [nix] metadata (store name, and the
relocated store paths it was built with: the candidates for references),
compute the REAPI Directory digest of the output (remotetool uploads any
blob the CAS lacks; 0 missing means the CAS already held the tree buck2
built), find its references by scanning for the candidates' hashes as Nix
would, and index it for the substituter. Its store path is a function of
digest and name (store_path; nix/buck2.nix computes the same). The digest
is pinned in PINS, which the flake reads.

usage: publish.py INDEX PINS TARGET...
"""

import hashlib
import json
import os
import subprocess
import sys

import cas
from storepath import STORE, add_to_index, index_entry, nix32, scan


def store_path(digest: str, name: str) -> str:
    """/nix/store/<hash>-<name> for a REAPI Directory digest "<sha256>:<size>"."""
    h = nix32(hashlib.sha256(f"buck2-reapi-directory:{digest}:{name}".encode()).digest())
    return f"{STORE}{h[:32]}-{name}"


def build(target):
    out = subprocess.run(["buck2", "build", target, "--show-full-json-output"],
                         check=True, capture_output=True, text=True).stdout
    (path,) = json.loads(out).values()
    return path


def closure_indexed(index, references):
    """Every store path the output needs must be servable: indexed, with its
    own references indexed in turn."""
    todo, seen = list(references), set()
    while todo:
        base = todo.pop()
        if base in seen:
            continue
        seen.add(base)
        entry = index_entry(index, base[:32])
        if not entry:
            raise SystemExit(f"{base} is not indexed; run `nix run .#push-closure`")
        todo.extend(entry["references"])


def main(index, pins_file, *targets):
    try:
        with open(pins_file) as f:
            pins = json.load(f)
    except FileNotFoundError:
        pins = {}
    for target in targets:
        out = build(target)
        with open(build(target + "[nix]")) as f:
            meta = json.load(f)
        digest, missing = cas.upload_dir(out)
        path = store_path(digest, meta["name"])
        references = sorted(scan(out, meta["candidates"]))
        closure_indexed(index, references)
        add_to_index(index, path, digest, references)
        pins[meta["name"]] = digest
        print(f"{target}\n  digest {digest}\n  store path {path}\n"
              f"  references {' '.join(references)}\n"
              f"  blobs missing from the CAS before publishing: {missing}")
    with open(pins_file, "w") as f:
        json.dump(pins, f, indent=2, sort_keys=True)
        f.write("\n")


if __name__ == "__main__":
    main(*sys.argv[1:])
