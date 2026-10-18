#!/bin/sh
# Create (once) and start the podman container that owns Nix for this repo.
# The host stays Nix-free: /nix lives in the nix-buck-store volume.
set -eu
cd "$(dirname "$0")/.."
name=nix-buck

if ! podman container exists "$name"; then
  podman volume exists nix-buck-store || podman volume create nix-buck-store
  podman run -d --name "$name" --hostname "$name" \
    --device /dev/kvm -v nix-buck-store:/nix -v "$PWD":/work:Z -w /work \
    docker.io/nixos/nix:latest sleep infinity
  podman exec "$name" sh -c '
    cat >> /etc/nix/nix.conf <<CONF
experimental-features = nix-command flakes
max-jobs = auto
cores = 0
sandbox = false
filter-syscalls = false
CONF
    git config --global --add safe.directory /work'
fi
podman start "$name" >/dev/null
