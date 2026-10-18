"""Write nix_closures.bzl: each relocated closure pinned by the REAPI
Directory digest it will have in any CAS, computed locally (nix/reapi.py).
Pure, so Nix builds it, and `nix flake check` compares it with the
committed copy.

usage: pins.py CLOSURES_JSON > nix_closures.bzl
  CLOSURES_JSON: name -> {"tree": a relocated closure (nix/store and
  closure.json, by nix/relocate.py), "originals": role -> nixpkgs basename}.
"""

import json
import os
import sys

import reapi


def main(closures_file):
    with open(closures_file) as f:
        closures = json.load(f)
    pinned = {}
    for name, closure in sorted(closures.items()):
        with open(os.path.join(closure["tree"], "closure.json")) as f:
            meta = json.load(f)
        pinned[name] = {
            "digest": reapi.digest(closure["tree"]),
            "roots": meta["roots"],
            "originals": closure["originals"],
            "references": meta["references"],
        }
    print("# Generated from the flake's relocated closures (nix/pins.py); install\n"
          "# with `nix run .#push-closure`. Do not edit.\n"
          "NIX_CLOSURES = " + json.dumps(pinned, indent=4, sort_keys=True))


if __name__ == "__main__":
    main(*sys.argv[1:])
