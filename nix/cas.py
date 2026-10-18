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


def _varint(b, i):
    r = s = 0
    while True:
        c = b[i]
        i += 1
        r |= (c & 0x7F) << s
        s += 7
        if c < 0x80:
            return r, i


def _fields(b):
    """Top-level (field, value) pairs of a protobuf message; enough for Directory."""
    i = 0
    while i < len(b):
        key, i = _varint(b, i)
        field, wire = key >> 3, key & 7
        if wire == 2:
            n, i = _varint(b, i)
            yield field, b[i:i + n]
            i += n
        elif wire == 0:
            v, i = _varint(b, i)
            yield field, v
        else:
            raise ValueError(f"unexpected wire type {wire}")


def subdirs(digest):
    """name -> digest of the subdirectories (DirectoryNodes, field 2) of a
    Directory in the CAS."""
    with tempfile.TemporaryDirectory() as tmp:
        path = os.path.join(tmp, "blob")
        remotetool("download_blob", "--digest=" + digest.replace(":", "/"), "--path=" + path)
        with open(path, "rb") as f:
            blob = f.read()
    out = {}
    for field, node in _fields(blob):
        if field == 2:
            n = dict(_fields(node))
            d = dict(_fields(n[2]))
            out[n[1].decode()] = "{}:{}".format(d[1].decode(), d.get(2, 0))
    return out
