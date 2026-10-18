#!/bin/sh
# Build and boot one of the VMs inside the nix-buck container, detached.
#   dev/vm.sh worker   NativeLink worker, REAPI on 127.0.0.1:50051
#   dev/vm.sh host     Nix host; runs .tmp-host/run.sh at boot, then powers off
# Each boot starts from a fresh disk. State and the console log live in
# /var/lib/vms/<name>/ in the container.
#
# The VM runs as an unprivileged uid (999, no passwd entry): virtiofsd cannot
# apply its capabilities as the rootless container's root, and Nix kills the
# processes of its nixbld* build users after every build. The serial console
# is on stdio, so stdin is held open by a pipe or qemu exits with the exec
# session.
set -eu
cd "$(dirname "$0")/.."
name=$1
dir=/var/lib/vms/$name
dev/container.sh
podman exec nix-buck sh -c "
  set -e
  # One instance per VM: stop a running one (its disk and ports are reused).
  for p in /proc/[0-9]*; do
    case \$(tr '\\0' ' ' < \$p/cmdline 2>/dev/null) in
      *qemu-system*-name\ nix-origin-$name\ *) kill \${p#/proc/}; sleep 1 ;;
    esac
  done
  nix build .#$name-vm -o result-$name-vm
  rm -rf $dir && mkdir -p $dir /work/.tmp-host
  chown -R 999:999 $dir /work/.tmp-host"
podman exec -d --user 999:999 -w "$dir" nix-buck sh -c "
  sleep infinity | TMPDIR=$dir /work/result-$name-vm/bin/run-nix-origin-$name-vm > $dir/console.log 2>&1"
echo "booting $name; console: podman exec nix-buck tail -f $dir/console.log"
