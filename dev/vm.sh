#!/bin/sh
# Build and boot one of the VMs inside the nix-buck container, detached.
#   dev/vm.sh worker          NativeLink worker, REAPI on 127.0.0.1:50051
#   dev/vm.sh host --wait     Nix host: runs /var/lib/vms/host-demo/run.sh at
#                             boot, writes out.txt beside it, powers off;
#                             --wait blocks until it has
# Each boot starts from a fresh disk. State and the console log live in
# /var/lib/vms/<name>/ in the container.
#
# The VM runs as an unprivileged uid (999, no passwd entry): virtiofsd cannot
# apply its capabilities as the rootless container's root, and Nix kills the
# processes of its nixbld* build users after every build. The serial console
# is on stdio; stdin is a FIFO opened read-write, which never reaches EOF, or
# qemu exits with the exec session.
set -eu
cd "$(dirname "$0")/.."
name=$1
dir=/var/lib/vms/$name

# PIDs of this VM's qemu. "[m]" keeps the pattern from matching the very
# shell that scans /proc, whose command line contains it.
pids="for p in /proc/[0-9]*; do
  case \$(tr '\\0' ' ' 2>/dev/null < \$p/cmdline) in
    *qemu-syste[m]*' -name nix-origin-$name '*) echo \${p#/proc/} ;;
  esac
done"

dev/container.sh
podman exec nix-buck sh -c "
  set -e
  # One instance per VM: stop a running one (its disk and ports are reused).
  for p in \$($pids); do kill \$p; sleep 1; done
  nix build .#$name-vm -o result-$name-vm
  rm -rf $dir && mkdir -p $dir
  chown -R 999:999 $dir"
podman exec -d --user 999:999 -w "$dir" nix-buck sh -c "
  mkfifo $dir/stdin && exec 0<>$dir/stdin > $dir/console.log 2>&1
  TMPDIR=$dir exec /work/result-$name-vm/bin/run-nix-origin-$name-vm"
echo "booting $name; console: podman exec nix-buck tail -f $dir/console.log"

if [ "${2:-}" = --wait ]; then
  # The run script prepares a disk before it starts qemu.
  podman exec nix-buck sh -c "
    i=0; until [ -n \"\$($pids)\" ]; do i=\$((i+1)); [ \$i -lt 120 ] || exit 1; sleep 1; done
    while [ -n \"\$($pids)\" ]; do sleep 2; done"
  echo "$name powered off"
fi
