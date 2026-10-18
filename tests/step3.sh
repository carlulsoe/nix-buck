#!/bin/sh
# Boot the worker VM, upload the relocated closure, and have buck2 compile,
# link and run hello.c on the worker: every command remote, nothing local.
set -eu
cd "$(dirname "$0")/.."
dev/vm.sh worker
echo "waiting for NativeLink on 127.0.0.1:50051..."
until podman exec nix-buck grep -q ':C383 00000000:0000 0A' /proc/net/tcp; do sleep 2; done

podman exec nix-buck sh -c '
  set -e
  export PATH=$(nix build --no-link --print-out-paths .#buck2)/bin:$PATH
  nix run .#push-closure > /dev/null
  # A fresh worker has a fresh CAS; drop the daemon'\''s memory of the old one.
  buck2 kill > /dev/null 2>&1 || true
  buck2 run //:hello-report --no-remote-cache 2>&1 | tee /tmp/step3.out
  grep -q "Commands: 3 (cached: 0, remote: 3, local: 0)" /tmp/step3.out
  grep -q "^kernel: *Linux 7\.3" /tmp/step3.out
  grep -q "^hostname: *nix-origin-worker" /tmp/step3.out
  grep -Eq "^/proc/self/exe: */var/lib/nativelink/work/.*/__hello__/root/nix/store/hello/bin/hello$" /tmp/step3.out
  grep -q "gcc-16.2.0 on this machine: absent" /tmp/step3.out
  echo "step 3: ok"'
