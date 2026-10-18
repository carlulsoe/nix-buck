"""The REAPI CAS through remotetool, as push-closure, publish and the
substituter use it. The endpoint is $CAS (default 127.0.0.1:50051),
instance "main".
"""

import json
import os
import subprocess
import tempfile

CAS = os.environ.get("CAS", "127.0.0.1:50051")


def remotetool(operation, *args):
    subprocess.run(["remotetool", "--operation=" + operation, "--service=" + CAS,
                    "--service_no_security", "--instance=main", "--alsologtostderr=false",
                    *args], check=True)


def upload_dir(path):
    """Upload a tree; return its Directory digest "<sha256>:<size>" and the
    number of blobs the CAS did not have."""
    with tempfile.TemporaryDirectory() as tmp:
        stats = os.path.join(tmp, "upload.json")
        remotetool("upload_dir", "--symlink_behavior=preserve", "--path=" + path, "--json=" + stats)
        with open(stats) as f:
            s = json.load(f)
    root = s["RootDigest"]
    return "{}:{}".format(root["Hash"], root["Size"]), s.get("CountCacheMisses", 0)


def download_dir(digest, path):
    remotetool("download_dir", "--digest=" + digest.replace(":", "/"), "--path=" + path)
