"""Publish buck2 outputs to the substituter's index.

For each target: build it and its [nix] metadata, compute the REAPI
Directory digest of the output tree (remotetool uploads any blob the CAS
lacks; 0 missing means the CAS already held the tree buck2 built), and write
the index entry the substituter serves a narinfo from. Prints the digest to
pin in flake.nix.

usage: publish.py INDEX TARGET...
"""

import json
import os
import subprocess
import sys
import tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from substituter import store_path  # noqa: E402


def build(target):
    out = subprocess.run(["buck2", "build", target, "--show-full-json-output"],
                         check=True, capture_output=True, text=True).stdout
    (path,) = json.loads(out).values()
    return path


def upload(path):
    with tempfile.TemporaryDirectory() as tmp:
        stats = os.path.join(tmp, "upload.json")
        subprocess.run([
            "remotetool", "--operation=upload_dir", "--service=" + os.environ.get("CAS", "127.0.0.1:50051"),
            "--service_no_security", "--instance=main", "--symlink_behavior=preserve",
            "--path=" + path, "--json=" + stats, "--alsologtostderr=false",
        ], check=True)
        with open(stats) as f:
            s = json.load(f)
    return "{}:{}".format(s["RootDigest"]["Hash"], s["RootDigest"]["Size"]), s.get("CountCacheMisses", 0)


def main(index, targets):
    os.makedirs(index, exist_ok=True)
    for target in targets:
        out = build(target)
        with open(build(target + "[nix]")) as f:
            meta = json.load(f)
        digest, missing = upload(out)
        path = store_path(digest, meta["name"])
        entry = {"target": target, "digest": digest, **meta}
        with open(os.path.join(index, os.path.basename(path)[:32] + ".json"), "w") as f:
            json.dump(entry, f, indent=2)
        print(f"{target}\n  digest = \"{digest}\";\n  store path {path}\n"
              f"  references {' '.join(meta['references'])}\n"
              f"  blobs missing from the CAS before publishing: {missing}")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2:])
