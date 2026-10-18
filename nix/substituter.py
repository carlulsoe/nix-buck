"""A Nix binary cache backed by a REAPI CAS.

Nix asks a substituter for /<hashpart>.narinfo and then for the NAR it names.
For buck2 outputs that were published (an index entry naming the REAPI
Directory digest, store name and references), the tree is read from the CAS
by digest, serialized as a NAR and served with a signed narinfo. Everything
else, such as the glibc a buck2 binary refers to, is proxied to an upstream
cache, so one substituter serves the whole closure.

The store path of a buck2 output is a function of its digest and name; see
store_path(). nix/buck2.nix computes the same function in the Nix language.

usage: substituter.py --index DIR --secret-key FILE [--cas HOST:PORT]
                      [--instance NAME] [--upstream URL] [--port N]
"""

import argparse
import base64
import hashlib
import http.server
import json
import os
import shutil
import subprocess
import tempfile
import threading
import urllib.error
import urllib.request

from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey

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


def store_path(digest: str, name: str) -> str:
    """/nix/store/<hash>-<name> for a REAPI Directory digest "<sha256>:<size>"."""
    h = nix32(hashlib.sha256(f"buck2-reapi-directory:{digest}:{name}".encode()).digest())
    return f"/nix/store/{h[:32]}-{name}"


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
    def __init__(self, args):
        self.args = args
        name, key = open(args.secret_key).read().strip().split(":", 1)
        self.key_name = name
        self.key = Ed25519PrivateKey.from_private_bytes(base64.b64decode(key)[:32])
        self.nars = {}
        self.lock = threading.Lock()

    def entry(self, hashpart):
        try:
            with open(os.path.join(self.args.index, hashpart + ".json")) as f:
                entry = json.load(f)
        except FileNotFoundError:
            return None
        path = store_path(entry["digest"], entry["name"])
        if not path.startswith(f"/nix/store/{hashpart}-"):
            raise ValueError(f"index entry {hashpart} does not match its digest")
        return path, entry

    def fetch_nar(self, hashpart, digest):
        """Read the tree out of the CAS by digest and archive it."""
        with self.lock:
            if hashpart in self.nars:
                return self.nars[hashpart]
            tmp = tempfile.mkdtemp()
            try:
                out = os.path.join(tmp, "out")
                subprocess.run([
                    "remotetool", "--operation=download_dir", f"--service={self.args.cas}",
                    "--service_no_security", f"--instance={self.args.instance}",
                    f"--digest={digest.replace(':', '/')}", f"--path={out}",
                    "--alsologtostderr=false",
                ], check=True)
                data = nar(out)
            finally:
                shutil.rmtree(tmp)
            self.nars[hashpart] = data
            return data

    def narinfo(self, hashpart):
        found = self.entry(hashpart)
        if not found:
            return None
        path, entry = found
        data = self.fetch_nar(hashpart, entry["digest"])
        nar_hash = "sha256:" + nix32(hashlib.sha256(data).digest())
        refs = sorted(entry["references"])
        fingerprint = ";".join(
            ["1", path, nar_hash, str(len(data)), ",".join("/nix/store/" + r for r in refs)])
        sig = base64.b64encode(self.key.sign(fingerprint.encode())).decode()
        return "".join(f"{k}: {v}\n" for k, v in [
            ("StorePath", path),
            ("URL", f"nar/{hashpart}.nar"),
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

        def proxy(self):
            req = urllib.request.Request(cache.args.upstream + self.path, method=self.command)
            try:
                with urllib.request.urlopen(req) as r:
                    self.reply(r.status, r.read(), r.headers.get("Content-Type", "text/plain"))
            except urllib.error.HTTPError as e:
                self.reply(e.code)

        def do_GET(self):
            p = self.path.lstrip("/")
            if p == "nix-cache-info":
                return self.reply(200, b"StoreDir: /nix/store\nWantMassQuery: 0\nPriority: 30\n")
            if p.endswith(".narinfo"):
                body = cache.narinfo(p[: -len(".narinfo")])
                return self.reply(200, body, "text/x-nix-narinfo") if body else self.proxy()
            if p.startswith("nar/") and p.endswith(".nar"):
                found = cache.entry(p[len("nar/"): -len(".nar")])
                if found:
                    hashpart = os.path.basename(found[0])[:32]
                    return self.reply(200, cache.fetch_nar(hashpart, found[1]["digest"]),
                                      "application/x-nix-nar")
            return self.proxy()

        do_HEAD = do_GET

    return Handler


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--index", required=True)
    ap.add_argument("--secret-key", required=True)
    ap.add_argument("--cas", default="127.0.0.1:50051")
    ap.add_argument("--instance", default="main")
    ap.add_argument("--upstream", default="https://cache.nixos.org")
    ap.add_argument("--port", type=int, default=8090)
    args = ap.parse_args()
    server = http.server.ThreadingHTTPServer(("0.0.0.0", args.port), handler(Cache(args)))
    print(f"serving {args.index} from {args.cas} on :{args.port}", flush=True)
    server.serve_forever()


if __name__ == "__main__":
    main()
