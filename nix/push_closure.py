"""Upload relocated closures to a REAPI CAS.

Each closure goes up as one tree. The CAS must report the root digest that
nix/reapi.py computes locally, which is what nix_closures.bzl pins: buck2
refers to the closure by that digest alone.

usage: push_closure.py CLOSURES_JSON   (see nix/pins.py)
"""

import json
import sys

import cas
import reapi


def main(closures_file):
    with open(closures_file) as f:
        closures = json.load(f)
    for name, closure in sorted(closures.items()):
        tree = closure["tree"]
        local = reapi.digest(tree)
        uploaded, missing = cas.upload_dir(tree)
        if uploaded != local:
            raise SystemExit(f"{name}: the CAS digests {tree} as {uploaded}, not {local}")
        print(f"{name}: {local}, {missing} blobs were missing from the CAS")


if __name__ == "__main__":
    main(*sys.argv[1:])
