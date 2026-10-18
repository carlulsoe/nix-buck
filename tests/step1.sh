#!/bin/sh
# Build the relocatable gcc closure, then compile and run hello with it in a
# Debian container that has no /nix.
set -eu
cd "$(dirname "$0")/.."
dev/container.sh
podman exec nix-buck sh -c '
  set -e
  nix build .#gcc-closure -o result-closure
  rm -rf .tmp-closure && mkdir .tmp-closure && cp -a result-closure/nix .tmp-closure/'
gcc=/nix/store/$(podman exec nix-buck nix eval --raw .#gcc-closure.originals.gcc)
podman run --rm -v "$PWD":/work:Z,ro -v "$PWD/.tmp-closure":/closure:Z,ro \
  --hostname nix-free docker.io/library/debian:bookworm-slim \
  sh /work/tests/relocated-gcc.sh /closure /work/src "$gcc"
