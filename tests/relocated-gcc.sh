#!/bin/sh
# Compile and run hello with a relocated gcc closure copied to a directory
# it was never built for, on a machine whose store lacks that gcc.
#
# With Linux 7.3 and the nix_origin binfmt_misc handler registered, the
# kernel resolves $ORIGIN in PT_INTERP and every tool is exec'd directly.
# Without it, every exec is routed through the closure's own ld.so: cc1, as
# and collect2 via gcc's -wrapper, and the ld that collect2 starts via a shim
# found first on the -B path. RUNPATH $ORIGIN resolution, header and crt
# lookup, and linking run for real either way. The routing stays while the
# machines running step 1 have kernels older than 7.3.
#
# usage: relocated-gcc.sh CLOSURE_DIR SRC_DIR NIX_GCC
#   CLOSURE_DIR contains nix/store; SRC_DIR has hello.c and report.c;
#   NIX_GCC is the store path hello reports on (nixpkgs' gcc).
set -eu

root=$(mktemp -d)/some/unrelated/place
mkdir -p "$root"
cp -a "$1/nix" "$root/"
S=$root/nix/store
chmod u+w "$S"

gcc=$(echo "$S"/*-gcc-16.2.0)
gcc_lib=$(echo "$S"/*-gcc-16.2.0-lib)
binutils=$(echo "$S"/*-binutils-2.46)
glibc=$(echo "$S"/*-glibc-2.44-25)
glibc_dev=$(echo "$S"/*-glibc-2.44-25-dev)
headers=$(echo "$S"/*-linux-headers-7.2)
ldso=$glibc/lib/ld-linux-x86-64.so.2
gcc_inc=$gcc/lib/gcc/x86_64-unknown-linux-gnu/16.2.0

test ! -e "$3" ||
  { echo "this machine already has $3 in its store" >&2; exit 1; }

if [ -e /proc/sys/fs/binfmt_misc/nix-origin ]; then
  echo "--- kernel resolves \$ORIGIN in PT_INTERP: exec'ing tools directly"
  run= via=
else
  echo "--- no \$ORIGIN handler: routing execs through the closure's ld.so"
  shims=$root/shims
  mkdir -p "$shims"
  printf '#!/bin/sh\nexec %s %s/bin/ld "$@"\n' "$ldso" "$binutils" > "$shims/ld"
  chmod +x "$shims/ld"
  run=$ldso via="-wrapper $ldso -B $shims/"
fi

# hello is laid out like a store path, as cc_binary will lay it out.
out=$S/hello/bin
mkdir -p "$out"
glibc_rel=../../$(basename "$glibc")/lib
gcc_lib_rel=../../$(basename "$gcc_lib")/lib

# $run and $via are deliberately unquoted: empty, or space-free paths.
$run "$gcc/bin/gcc" $via -B "$binutils/bin/" -B "$glibc/lib/" \
  -nostdinc -isystem "$gcc_inc/include" -isystem "$gcc_inc/include-fixed" \
  -isystem "$glibc_dev/include" -isystem "$headers/include" \
  -L "$glibc/lib" -L "$gcc_lib/lib" \
  -Wl,--dynamic-linker="\$ORIGIN/$glibc_rel/ld-linux-x86-64.so.2" \
  -Wl,-rpath,"\$ORIGIN/$glibc_rel:\$ORIGIN/$gcc_lib_rel" \
  -DNIX_GCC="\"$3\"" -I "$2" \
  -o "$out/hello" "$2/hello.c" "$2/report.c"

echo "--- hello's loader strings"
$run "$binutils/bin/readelf" -lW "$out/hello" | grep -o 'program interpreter: [^]]*'
$run "$binutils/bin/readelf" -dW "$out/hello" | grep -E 'RUNPATH|NEEDED'

echo "--- hello"
$run "$out/hello"
