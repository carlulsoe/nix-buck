"""REAPI Directory digests of a local tree, without a CAS.

Computed as remotetool's upload_dir --symlink_behavior=preserve computes
them: a Directory message per directory, with its files, subdirectories and
symlinks each sorted by name, serialized canonically (fields in order,
defaults omitted), and digested as "<sha256>:<size>".

usage: reapi.py DIR   prints the digest of DIR
"""

import hashlib
import os
import stat
import sys


def _varint(n):
    out = bytearray()
    while True:
        b = n & 0x7F
        n >>= 7
        if n:
            out.append(b | 0x80)
        else:
            out.append(b)
            return bytes(out)


def _bytes(field, payload):
    return _varint(field << 3 | 2) + _varint(len(payload)) + payload


def _digest(h, size):
    msg = _bytes(1, h.encode())
    return msg + (_varint(2 << 3) + _varint(size) if size else b"")


def _file_digest(path):
    h = hashlib.sha256()
    size = 0
    with open(path, "rb") as f:
        while chunk := f.read(1 << 20):
            h.update(chunk)
            size += len(chunk)
    return h.hexdigest(), size


def tree(path, subdirs=None, rel=""):
    """The digest of the tree at path. If subdirs is a dict, it collects the
    digest of every directory below, keyed by path relative to the top."""
    files, dirs, links = [], [], []
    for name in sorted(os.listdir(path), key=os.fsencode):
        p = os.path.join(path, name)
        st = os.lstat(p)
        if stat.S_ISLNK(st.st_mode):
            links.append(_bytes(3, _bytes(1, name.encode()) + _bytes(2, os.readlink(p).encode())))
        elif stat.S_ISDIR(st.st_mode):
            sub = tree(p, subdirs, os.path.join(rel, name))
            dirs.append(_bytes(2, _bytes(1, name.encode()) + _bytes(2, _digest(*sub))))
        else:
            node = _bytes(1, name.encode()) + _bytes(2, _digest(*_file_digest(p)))
            if st.st_mode & 0o100:
                node += _varint(4 << 3) + _varint(1)
            files.append(_bytes(1, node))
    blob = b"".join(files + dirs + links)
    digest = (hashlib.sha256(blob).hexdigest(), len(blob))
    if subdirs is not None and rel:
        subdirs[rel] = "{}:{}".format(*digest)
    return digest


def digest(path, subdirs=None):
    return "{}:{}".format(*tree(path, subdirs))


if __name__ == "__main__":
    print(digest(sys.argv[1]))
