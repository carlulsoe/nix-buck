"""A Nix binary cache backed by a REAPI CAS.

Nix asks a substituter for /<hashpart>.narinfo and then for the NAR it names.
For every store path in the index (the relocated closures, by push-closure,
and published buck2 outputs, by publish), the tree is read from the CAS by
its Directory digest, serialized as a NAR and served with a signed narinfo.
Nothing else is served: an indexed path's references are indexed too.

usage: substituter.py --index DIR --secret-key FILE [--port N]
  The CAS is $CAS (default 127.0.0.1:50051).
"""

import argparse
import base64
import hashlib
import http.server
import os
import shutil
import tempfile
import threading

from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey

import cas
from storepath import STORE, index_entry, nix32


def nar(path: str) -> bytes:
    """Serialize a directory tree as a Nix archive."""
    out = bytearray()

    def s(x):
        x = x.encode() if isinstance(x, str) else x
        out.extend(len(x).to_bytes(8, "little"))
        out.extend(x)
        out.extend(b"\0" * (-len(x) % 8))

    def node(p):
        s("(")
        s("type")
        if os.path.islink(p):
            s("symlink")
            s("target")
            s(os.readlink(p))
        elif os.path.isdir(p):
            s("directory")
            for name in sorted(os.listdir(p), key=os.fsencode):
                s("entry")
                s("(")
                s("name")
                s(name)
                s("node")
                node(os.path.join(p, name))
                s(")")
        else:
            s("regular")
            if os.access(p, os.X_OK):
                s("executable")
                s("")
            s("contents")
            with open(p, "rb") as f:
                s(f.read())
        s(")")

    s("nix-archive-1")
    node(path)
    return bytes(out)


class Cache:
    def __init__(self, index, secret_key):
        self.index = index
        name, key = open(secret_key).read().strip().split(":", 1)
        self.key_name = name
        self.key = Ed25519PrivateKey.from_private_bytes(base64.b64decode(key)[:32])
        self.nars = {}
        self.lock = threading.Lock()

    def nar(self, entry):
        """Read the tree out of the CAS by digest and archive it."""
        with self.lock:
            if entry["digest"] not in self.nars:
                tmp = tempfile.mkdtemp()
                try:
                    out = os.path.join(tmp, "out")
                    cas.download_dir(entry["digest"], out)
                    self.nars[entry["digest"]] = nar(out)
                finally:
                    shutil.rmtree(tmp)
            return self.nars[entry["digest"]]

    def narinfo(self, entry):
        data = self.nar(entry)
        path, refs = entry["path"], entry["references"]
        nar_hash = "sha256:" + nix32(hashlib.sha256(data).digest())
        fingerprint = ";".join(["1", path, nar_hash, str(len(data)), ",".join(STORE + r for r in refs)])
        sig = base64.b64encode(self.key.sign(fingerprint.encode())).decode()
        return "".join(f"{k}: {v}\n" for k, v in [
            ("StorePath", path),
            ("URL", f"nar/{os.path.basename(path)[:32]}.nar"),
            ("Compression", "none"),
            ("NarHash", nar_hash),
            ("NarSize", len(data)),
            ("References", " ".join(refs)),
            ("Sig", f"{self.key_name}:{sig}"),
        ]).encode()


def handler(cache):
    class Handler(http.server.BaseHTTPRequestHandler):
        def reply(self, status, body=b"", ctype="text/plain"):
            self.send_response(status)
            self.send_header("Content-Type", ctype)
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            if self.command != "HEAD":
                self.wfile.write(body)

        def do_GET(self):
            p = self.path.lstrip("/")
            if p == "nix-cache-info":
                return self.reply(200, b"StoreDir: /nix/store\nWantMassQuery: 0\nPriority: 30\n")
            for suffix, prefix, serve, ctype in [
                (".narinfo", "", cache.narinfo, "text/x-nix-narinfo"),
                (".nar", "nar/", cache.nar, "application/x-nix-nar"),
            ]:
                if p.startswith(prefix) and p.endswith(suffix):
                    entry = index_entry(cache.index, p[len(prefix):-len(suffix)])
                    if entry:
                        return self.reply(200, serve(entry), ctype)
            return self.reply(404)

        do_HEAD = do_GET

    return Handler


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--index", required=True)
    ap.add_argument("--secret-key", required=True)
    ap.add_argument("--port", type=int, default=8090)
    args = ap.parse_args()
    server = http.server.ThreadingHTTPServer(("0.0.0.0", args.port), handler(Cache(args.index, args.secret_key)))
    print(f"serving {args.index} from {cas.CAS} on :{args.port}", flush=True)
    server.serve_forever()


if __name__ == "__main__":
    main()
