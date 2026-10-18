"""Upload relocated closures to a REAPI CAS and index their store paths for
the substituter.

Each closure goes up as one tree. The CAS must report the root digest that
nix/reapi.py computes locally, which is what nix_closures.bzl pins. Each
store path in it is a subtree with a digest of its own, indexed with its
references so the substituter can serve it to Nix. A store path in several
closures must have the same digest in each, and the same as any earlier
upload: one name, one content.

usage: push_closure.py INDEX CLOSURES_JSON   (see nix/pins.py)
"""

import json
import os
import sys

import cas
import reapi
from storepath import STORE, add_to_index


def main(index, closures_file):
    with open(closures_file) as f:
        closures = json.load(f)
    for name, closure in sorted(closures.items()):
        tree = closure["tree"]
        subdirs = {}
        local = reapi.digest(tree, subdirs)
        uploaded, missing = cas.upload_dir(tree)
        if uploaded != local:
            raise SystemExit(f"{name}: the CAS digests {tree} as {uploaded}, not {local}")
        with open(os.path.join(tree, "closure.json")) as f:
            references = json.load(f)["references"]
        for base, refs in references.items():
            add_to_index(index, STORE + base, subdirs[os.path.join("nix", "store", base)], refs)
        print(f"{name}: {local}, {len(references)} store paths, {missing} blobs were missing from the CAS")


if __name__ == "__main__":
    main(*sys.argv[1:])
