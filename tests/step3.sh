#!/bin/sh
# Boot the worker VM, upload the relocated closures, and have buck2 compile,
# archive, link and run hello and zhello (zlib from nixpkgs, a buck2-built
# static library) on the worker: every command remote, nothing local.
set -eu
cd "$(dirname "$0")/.."
dev/vm.sh worker
echo "waiting for NativeLink on 127.0.0.1:50051..."
until podman exec nix-buck grep -q ':C383 00000000:0000 0A' /proc/net/tcp; do sleep 2; done

podman exec nix-buck sh -c '
  set -e
  export PATH=$(nix build --no-link --print-out-paths .#buck2)/bin:$PATH
  nix run .#push-closure
  git diff --exit-code nix_closures.bzl
  # A fresh worker has a fresh CAS; drop the daemon'\''s memory of the old one.
  buck2 kill > /dev/null 2>&1 || true
  buck2 build //:hello-report //:zhello-report --no-remote-cache 2>&1 | tee /tmp/step3.out
  # 3 compiles, ar, 2 links, 2 runs.
  grep -q "Commands: 8 (cached: 0, remote: 8, local: 0)" /tmp/step3.out
  gcc=/nix/store/$(nix eval --raw .#gcc-closure.originals.gcc)
  for t in hello zhello; do
    buck2 run //:$t-report 2>/dev/null | tee /tmp/step3.$t
    grep -q "^kernel: *Linux 7\.3" /tmp/step3.$t
    grep -q "^hostname: *nix-origin-worker" /tmp/step3.$t
    grep -Eq "^/proc/self/exe: */var/lib/nativelink/work/.*/__${t}__/root/nix/store/$t/bin/$t$" /tmp/step3.$t
    grep -Eq "^libc: .*/root/nix/store/$t/bin/\.\./\.\./[a-z0-9]{32}-glibc-2\.44-25/lib/libc\.so\.6$" /tmp/step3.$t
    grep -qx "$gcc on this machine: absent" /tmp/step3.$t
  done
  grep -qx "zlib: *1\.3\.2, round trip ok" /tmp/step3.zhello
  grep -Eq "^libz: .*/root/nix/store/zhello/bin/\.\./\.\./[a-z0-9]{32}-zlib-1\.3\.2/lib/libz\.so\.1$" /tmp/step3.zhello
  echo "step 3: ok"'
