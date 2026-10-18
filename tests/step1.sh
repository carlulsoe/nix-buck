#!/bin/sh
# Build the relocatable gcc closure, then compile and run hello.c with it in a
# Debian container that has no /nix.
set -eu
cd "$(dirname "$0")/.."
dev/container.sh
podman exec nix-buck sh -c '
  nix build .#gcc-closure -o result-closure
  rm -rf .tmp-closure && mkdir .tmp-closure && cp -a result-closure/nix .tmp-closure/'
podman run --rm -v "$PWD":/work:Z,ro -v "$PWD/.tmp-closure":/closure:Z,ro \
  --hostname nix-free docker.io/library/debian:bookworm-slim \
  sh /work/tests/relocated-gcc.sh /closure /work/hello.c
