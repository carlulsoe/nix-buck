#!/bin/sh
# buck2 output -> Nix store path. After step 3 built //:hello on the worker:
# publish it, substitute it into the container's store by its pinned digest
# (fetchClosure through nix/substituter.py, which reads the CAS), and do the
# same on a Linux 7.3 Nix host VM, where it runs natively.
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
  digest=$(grep -o "[0-9a-f]\{64\}:[0-9]*" flake.nix)
  path=$(nix eval --raw .#lib.buck2 --apply "b: b.storePath { name = \"hello\"; digest = \"$digest\"; }")
  key=$(cat .nix-buck/public-key)

  nix run .#publish -- //:hello | tee /tmp/step4.publish
  # buck2 built exactly the tree flake.nix pins, and it was already in the CAS.
  grep -qx "  digest = \"$digest\";" /tmp/step4.publish
  grep -qx "  store path $path" /tmp/step4.publish
  grep -qx "  blobs missing from the CAS before publishing: 0" /tmp/step4.publish

  rm -f result-hello
  # Substitute it afresh: it must not be in the store already.
  if [ -e "$path" ] && ! nix store delete "$path" > /dev/null 2>&1; then
    echo "$path is still alive; roots:"; nix-store -q --roots "$path"; exit 1
  fi
  nix build .#hello -o result-hello --extra-experimental-features fetch-closure \
    --option extra-trusted-public-keys "$key" 2>&1 | tee /tmp/step4.build
  grep -q "copying path .$path. from .http://127.0.0.1:8090." /tmp/step4.build
  [ "$(readlink -f result-hello)" = "$path" ]
  nix-store -q --references "$path" | tee /tmp/step4.refs
  [ "$(wc -l < /tmp/step4.refs)" = 2 ]
  grep -q -- "-glibc-2.44-25$" /tmp/step4.refs
  grep -q -- "-gcc-16.2.0-lib$" /tmp/step4.refs
  out=$(buck2 build //:hello --show-full-json-output | grep -o "\"/[^\"]*\"" | tr -d "\"")
  [ "$(nix hash path "$path")" = "$(nix hash path "$out")" ]
  echo "store path $path has the bytes buck2 built"

  # The same through a Nix host on 7.3, where the binary runs without help.
  mkdir -p /var/lib/vms/host-demo && rm -f /var/lib/vms/host-demo/out.txt
  cat > /var/lib/vms/host-demo/run.sh <<EOF
set -e
nix build --impure --extra-experimental-features fetch-closure \\
  --option extra-trusted-public-keys "$key" -o /tmp/result --expr \\
  "builtins.fetchClosure { fromStore = \"http://10.0.2.2:8090\"; fromPath = $path; inputAddressed = true; }"
/tmp/result/bin/hello
EOF
  chown -R 999:999 /var/lib/vms/host-demo
  echo "$path" > /tmp/step4.path'

dev/vm.sh host --wait
podman exec nix-buck sh -c '
  set -e
  path=$(cat /tmp/step4.path)
  cat /var/lib/vms/host-demo/out.txt
  grep -q "copying path .$path. from .http://10.0.2.2:8090." /var/lib/vms/host-demo/out.txt
  grep -q "^kernel: *Linux 7\.3" /var/lib/vms/host-demo/out.txt
  grep -q "^hostname: *nix-origin-host" /var/lib/vms/host-demo/out.txt
  grep -qx "/proc/self/exe: *$path/bin/hello" /var/lib/vms/host-demo/out.txt
  grep -q "gcc-16.2.0 on this machine: absent" /var/lib/vms/host-demo/out.txt
  echo "step 4: ok"'
