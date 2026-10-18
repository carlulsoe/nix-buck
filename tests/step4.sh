#!/bin/sh
# buck2 outputs -> Nix store paths. After step 3 built hello and zhello on
# the worker: publish them, substitute them into the container's store by
# their pinned digests (fetchClosure through nix/substituter.py, which reads
# the CAS), closure and all, and do the same on a Linux 7.3 Nix host VM,
# where they run natively.
set -eu
cd "$(dirname "$0")/.."
tests/step3.sh

podman exec nix-buck sh -c '
  set -e
  for p in /proc/[0-9]*; do
    case $(tr "\0" " " 2>/dev/null < $p/cmdline) in *substitute[r].py*) kill ${p#/proc/} ;; esac
  done'
podman exec -d -w /work nix-buck sh -c 'exec nix run .#substituter > /tmp/substituter.log 2>&1'
echo "waiting for the substituter on :8090..."
until podman exec nix-buck grep -q ':1F9A 00000000:0000 0A' /proc/net/tcp; do sleep 1; done

podman exec nix-buck sh -c '
  set -e
  export PATH=$(nix build --no-link --print-out-paths .#buck2)/bin:$PATH
  key=$(cat .nix-buck/public-key)
  originals=$(nix eval --json .#gcc-closure.originals)

  nix run .#publish -- //:hello //:zhello | tee /tmp/step4.publish
  # buck2 built exactly the trees buck2-pins.json pins, and they were
  # already in the CAS: the worker had them as inputs to run them.
  git diff --exit-code buck2-pins.json
  [ "$(grep -c "^  blobs missing from the CAS before publishing: 0$" /tmp/step4.publish)" = 2 ]

  : > /tmp/step4.paths
  for t in hello zhello; do
    digest=$(grep -o "\"$t\": \"[0-9a-f]*:[0-9]*\"" buck2-pins.json | cut -d\" -f4)
    path=$(nix eval --raw .#lib.buck2 --apply "b: b.storePath { name = \"$t\"; digest = \"$digest\"; }")
    grep -qx "  store path $path" /tmp/step4.publish
    echo "$path" >> /tmp/step4.paths

    # Substitute it afresh: it must not be in the store already.
    rm -f result-$t
    if [ -e "$path" ] && ! nix store delete "$path" > /dev/null 2>&1; then
      echo "$path is still alive; roots:"; nix-store -q --roots "$path"; exit 1
    fi
    nix build .#$t -o result-$t --extra-experimental-features fetch-closure \
      --option extra-trusted-public-keys "$key" 2>&1 | tee /tmp/step4.build
    grep -q "copying path .$path. from .http://127.0.0.1:8090." /tmp/step4.build
    [ "$(readlink -f result-$t)" = "$path" ]

    # Its references are the relocated runtime libraries it was linked
    # with, found by scanning; never gcc, never an unrelocated original.
    nix-store -q --references "$path" | tee /tmp/step4.refs
    grep -q -- "-glibc-2.44-25$" /tmp/step4.refs
    grep -q -- "-gcc-16.2.0-lib$" /tmp/step4.refs
    if [ $t = zhello ]; then n=3; grep -q -- "-zlib-1.3.2$" /tmp/step4.refs; else n=2; fi
    [ "$(wc -l < /tmp/step4.refs)" = $n ]
    # Every path in its closure is a relocated one the substituter indexed.
    for p in $(nix-store -qR "$path"); do
      h=$(basename "$p" | cut -c1-32)
      [ -e .nix-buck/index/$h.json ] || { echo "$p did not come from the CAS"; exit 1; }
      case "$originals" in *$h*) echo "$p is an unrelocated original"; exit 1 ;; esac
    done

    out=$(buck2 build //:$t --show-full-json-output | grep -o "\"/[^\"]*\"" | tr -d "\"")
    [ "$(nix hash path "$path")" = "$(nix hash path "$out")" ]
    echo "store path $path has the bytes buck2 built"
  done

  # The same through a Nix host on 7.3, where the binaries run without help.
  mkdir -p /var/lib/vms/host-demo && rm -f /var/lib/vms/host-demo/out.txt
  {
    echo "set -e"
    for path in $(cat /tmp/step4.paths); do
      echo "nix build --impure --extra-experimental-features fetch-closure \\"
      echo "  --option extra-trusted-public-keys \"$key\" -o /tmp/result --expr \\"
      echo "  \"builtins.fetchClosure { fromStore = \\\"http://10.0.2.2:8090\\\"; fromPath = $path; inputAddressed = true; }\""
      echo "$path/bin/$(basename "$path" | cut -c34-)"
    done
  } > /var/lib/vms/host-demo/run.sh
  chown -R 999:999 /var/lib/vms/host-demo'

dev/vm.sh host --wait
podman exec nix-buck sh -c '
  set -e
  out=/var/lib/vms/host-demo/out.txt
  cat $out
  gcc=/nix/store/$(nix eval --raw .#gcc-closure.originals.gcc)
  for path in $(cat /tmp/step4.paths); do
    t=$(basename "$path" | cut -c34-)
    grep -q "copying path .$path. from .http://10.0.2.2:8090." $out
    grep -qx "/proc/self/exe: *$path/bin/$t" $out
    grep -Eqx "libc: *$path/bin/\.\./\.\./[a-z0-9]{32}-glibc-2\.44-25/lib/libc\.so\.6" $out
  done
  grep -Eqx "libz: */nix/store/[a-z0-9]{32}-zhello/bin/\.\./\.\./[a-z0-9]{32}-zlib-1\.3\.2/lib/libz\.so\.1" $out
  grep -qx "zlib: *1\.3\.2, round trip ok" $out
  [ "$(grep -c "^kernel: *Linux 7\.3" $out)" = 2 ]
  [ "$(grep -c "^hostname: *nix-origin-host$" $out)" = 2 ]
  [ "$(grep -cx "$gcc on this machine: absent" $out)" = 2 ]
  echo "step 4: ok"'
