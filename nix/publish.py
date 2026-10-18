"""Publish buck2 outputs as Nix store paths, in a static binary cache.

For each target: build it and its [nix] metadata (store name, and the
relocated store paths it was built with: the candidates for references),
compute the REAPI Directory digest of the output locally (nix/reapi.py: the
digest buck2 and the CAS have for it), and find its references by scanning
for the candidates' hashes as Nix would. Its store path is a function of
digest and name (store_path; nix/buck2.nix computes the same). The output
and every relocated store path it needs go into the cache, NARs made from
the local trees; the digest is pinned in PINS, which the flake reads.

usage: publish.py CACHE SECRET_KEY PINS CLOSURES_JSON TARGET...
  CLOSURES_JSON: the relocated closures, as nix/pins.py takes them.
"""

import hashlib
import json
import os
import subprocess
import sys

import reapi
from binary_cache import BinaryCache
from storepath import STORE, nix32, scan


def store_path(digest: str, name: str) -> str:
    """/nix/store/<hash>-<name> for a REAPI Directory digest "<sha256>:<size>"."""
    h = nix32(hashlib.sha256(f"buck2-reapi-directory:{digest}:{name}".encode()).digest())
    return f"{STORE}{h[:32]}-{name}"


def build(target):
    out = subprocess.run(["buck2", "build", target, "--show-full-json-output"],
                         check=True, capture_output=True, text=True).stdout
    (path,) = json.loads(out).values()
    return path


def relocated_paths(closures_file):
    """basename -> (tree, references) for every relocated store path."""
    with open(closures_file) as f:
        closures = json.load(f)
    paths = {}
    for closure in closures.values():
        with open(os.path.join(closure["tree"], "closure.json")) as f:
            for base, refs in json.load(f)["references"].items():
                paths[base] = (os.path.join(closure["tree"], "nix", "store", base), refs)
    return paths


def main(cache_dir, secret_key, pins_file, closures_file, *targets):
    cache = BinaryCache(cache_dir, secret_key)
    relocated = relocated_paths(closures_file)
    try:
        with open(pins_file) as f:
            pins = json.load(f)
    except FileNotFoundError:
        pins = {}
    for target in targets:
        out = build(target)
        with open(build(target + "[nix]")) as f:
            meta = json.load(f)
        digest = reapi.digest(out)
        path = store_path(digest, meta["name"])
        references = sorted(scan(out, meta["candidates"]))

        # The output, then everything it needs, so the cache holds its closure.
        added = [path] if cache.add(path, out, references) else []
        todo, seen = list(references), set()
        while todo:
            base = todo.pop()
            if base in seen:
                continue
            seen.add(base)
            tree, refs = relocated[base]
            if cache.add(STORE + base, tree, refs):
                added.append(STORE + base)
            todo.extend(refs)

        pins[meta["name"]] = digest
        print(f"{target}\n  digest {digest}\n  store path {path}\n"
              f"  references {' '.join(references)}\n"
              f"  closure: {len(seen) + 1} store paths, {len(added)} newly in the cache")
    with open(pins_file, "w") as f:
        json.dump(pins, f, indent=2, sort_keys=True)
        f.write("\n")


if __name__ == "__main__":
    main(*sys.argv[1:])
