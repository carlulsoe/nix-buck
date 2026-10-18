#!/bin/sh
# Boot the worker VM, upload the relocated closures, and have buck2 compile,
# archive, link and run hello and zhello (zlib from nixpkgs, a buck2-built
# static library) on the worker: every command remote, nothing local, and
# every action sandboxed so it sees nothing of the worker but its inputs.
set -eu
cd "$(dirname "$0")/.."
dev/vm.sh worker

podman exec nix-buck sh -c '
  set -e
  for p in $(nix build --no-link --print-out-paths .#buck2 .#remotetool); do PATH=$p/bin:$PATH; done
  # qemu forwards the port before NativeLink is up: wait for the CAS itself
  # to answer (with the empty blob).
  echo "waiting for NativeLink on 127.0.0.1:50051..."
  for i in $(seq 90); do
    remotetool --operation=download_blob --service=127.0.0.1:50051 --service_no_security \
      --instance=main --alsologtostderr=false --path=/tmp/step3.ready \
      --digest=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855/0 \
      > /dev/null 2>&1 && break
    [ $i != 90 ] || { echo "NativeLink did not come up" >&2; exit 1; }
    sleep 2
  done
  nix run .#push-closure
  git diff --exit-code nix_closures.bzl
  # A fresh worker has a fresh CAS; drop the daemon'\''s memory of the old one.
  buck2 kill > /dev/null 2>&1 || true
  buck2 build //:hello-report //:zhello-report //:probe-report --no-remote-cache 2>&1 | tee /tmp/step3.out
  # 4 compiles, ar, 3 links, 3 runs.
  grep -q "Commands: 11 (cached: 0, remote: 11, local: 0)" /tmp/step3.out
  buck2 run //:probe-report 2>/dev/null | tee /tmp/step3.probe
  grep -qx "/nix/store: hidden" /tmp/step3.probe
  if grep -v ": hidden$" /tmp/step3.probe | grep -vx "network interfaces besides lo: 0"; then
    echo "actions see the worker" >&2; exit 1
  fi
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
