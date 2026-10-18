#!/bin/sh
# Smoke-test a relocated gcc closure on a machine without /nix.
#
# The kernel only resolves $ORIGIN in PT_INTERP from Linux 7.3 with the
# nix_origin binfmt_misc handler. Before that, every exec is routed through
# the closure's own ld.so: cc1, as and collect2 via gcc's -wrapper, and the
# ld that collect2 starts via a shim found first on the -B path. RUNPATH
# $ORIGIN resolution, header and crt lookup, and linking all run for real from a directory the closure was never built for.
#
# usage: relocated-gcc.sh CLOSURE_DIR HELLO_C   (CLOSURE_DIR contains nix/store)
set -eu

test ! -e /nix || { echo "this test needs a machine without /nix" >&2; exit 1; }

root=$(mktemp -d)/some/unrelated/place
mkdir -p "$root"
cp -a "$1/nix" "$root/"
S=$root/nix/store

gcc=$(echo "$S"/*-gcc-16.2.0)
gcc_lib=$(echo "$S"/*-gcc-16.2.0-lib)
binutils=$(echo "$S"/*-binutils-2.46)
glibc=$(echo "$S"/*-glibc-2.44-25)
glibc_dev=$(echo "$S"/*-glibc-2.44-25-dev)
headers=$(echo "$S"/*-linux-headers-7.2)
ldso=$glibc/lib/ld-linux-x86-64.so.2
gcc_inc=$gcc/lib/gcc/x86_64-unknown-linux-gnu/16.2.0

shims=$root/shims
mkdir -p "$shims"
printf '#!/bin/sh\nexec %s %s/bin/ld "$@"\n' "$ldso" "$binutils" > "$shims/ld"
chmod +x "$shims/ld"

# hello is laid out like a store path, as cc_binary will lay it out.
out=$S/hello/bin
mkdir -p "$out"
glibc_rel=../../$(basename "$glibc")/lib
gcc_lib_rel=../../$(basename "$gcc_lib")/lib

"$ldso" "$gcc/bin/gcc" -wrapper "$ldso" -B "$shims/" -B "$binutils/bin/" -B "$glibc/lib/" \
  -nostdinc -isystem "$gcc_inc/include" -isystem "$gcc_inc/include-fixed" \
  -isystem "$glibc_dev/include" -isystem "$headers/include" \
  -L "$glibc/lib" -L "$gcc_lib/lib" \
  -Wl,--dynamic-linker="\$ORIGIN/$glibc_rel/ld-linux-x86-64.so.2" \
  -Wl,-rpath,"\$ORIGIN/$glibc_rel:\$ORIGIN/$gcc_lib_rel" \
  -DNIX_GCC="\"/nix/store/$(basename "$gcc")\"" \
  -o "$out/hello" "$2"

echo "--- hello's loader strings"
"$ldso" "$binutils/bin/readelf" -lW "$out/hello" | grep -o 'program interpreter: [^]]*'
"$ldso" "$binutils/bin/readelf" -dW "$out/hello" | grep -E 'RUNPATH|NEEDED'

echo "--- hello, run through the relocated loader"
"$ldso" "$out/hello"
