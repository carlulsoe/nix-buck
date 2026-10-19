"""A static Nix binary cache: a directory of files any Nix can read, as
file://... or from any static web server or bucket it is copied to.
(fetchClosure, which the flake uses, reads only http(s) stores.)

    nix-cache-info
    <hashpart>.narinfo        signed; written last, so it marks a complete path
    nar/<filehash>.nar.zst

One store path, one content: adding a path that is already in the cache
with another NAR hash is an error.

A stand-in for Nix substituting from the REAPI CAS; see `publish` in
flake.nix for when it goes.
"""

import base64
import hashlib
import os
import tempfile
from compression import zstd

from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey

from storepath import STORE, nix32


def nar(path: str) -> bytes:
    """Serialize a tree as a Nix archive."""
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


def _narinfo_fields(text):
    return dict(line.split(": ", 1) for line in text.splitlines() if ": " in line)


class BinaryCache:
    def __init__(self, root, secret_key_file):
        self.root = root
        with open(secret_key_file) as f:
            self.key_name, key = f.read().strip().split(":", 1)
        self.key = Ed25519PrivateKey.from_private_bytes(base64.b64decode(key)[:32])
        os.makedirs(os.path.join(root, "nar"), exist_ok=True)
        self._write("nix-cache-info", b"StoreDir: /nix/store\nWantMassQuery: 1\nPriority: 30\n")

    def _write(self, rel, data):
        path = os.path.join(self.root, rel)
        fd, tmp = tempfile.mkstemp(dir=os.path.dirname(path))
        with os.fdopen(fd, "wb") as f:
            f.write(data)
        os.chmod(tmp, 0o644)
        os.replace(tmp, path)

    def add(self, store_path, tree, references):
        """Add the store path whose contents are `tree`. Returns True if it
        was added, False if the cache already had it."""
        hashpart = os.path.basename(store_path)[:32]
        data = nar(tree)
        nar_hash = "sha256:" + nix32(hashlib.sha256(data).digest())
        info_file = os.path.join(self.root, hashpart + ".narinfo")
        if os.path.exists(info_file):
            with open(info_file) as f:
                old = _narinfo_fields(f.read())
            if old["StorePath"] != store_path or old["NarHash"] != nar_hash:
                raise SystemExit(f"{store_path} is already in {self.root} with other contents")
            return False

        packed = zstd.compress(data)
        file_hash = nix32(hashlib.sha256(packed).digest())
        url = f"nar/{file_hash}.nar.zst"
        self._write(url, packed)
        refs = sorted(references)
        fingerprint = ";".join(["1", store_path, nar_hash, str(len(data)),
                                ",".join(STORE + r for r in refs)])
        sig = base64.b64encode(self.key.sign(fingerprint.encode())).decode()
        self._write(hashpart + ".narinfo", "".join(f"{k}: {v}\n" for k, v in [
            ("StorePath", store_path),
            ("URL", url),
            ("Compression", "zstd"),
            ("FileHash", "sha256:" + file_hash),
            ("FileSize", len(packed)),
            ("NarHash", nar_hash),
            ("NarSize", len(data)),
            ("References", " ".join(refs)),
            ("Sig", f"{self.key_name}:{sig}"),
        ]).encode())
        return True
