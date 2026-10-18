# The kernel's own $ORIGIN PT_INTERP handler
# (tools/testing/selftests/exec/nix_origin.bpf.c), built against the BTF of
# the kernel it will be loaded into.
#
# One change: the selftest uses classic dispatch, where ld.so becomes the
# exec'd program (/proc/self/exe names the loader). We request loader
# substitution instead, so the binary runs as a native exec and only its
# PT_INTERP is swapped, as in the article's output.
{ stdenvNoCC, kernel, bpftools, libbpf, llvmPackages }:

stdenvNoCC.mkDerivation {
  pname = "nix-origin-bpf";
  version = kernel.version;
  src = kernel.src;

  nativeBuildInputs = [ bpftools llvmPackages.clang-unwrapped ];

  # Only the one file is needed; src is a tarball for releases, a tree for -rc.
  unpackPhase = ''
    f=tools/testing/selftests/exec/nix_origin.bpf.c
    if [ -d $src ]; then cp $src/$f .; else tar -xf $src --wildcards --strip-components=5 "*/$f"; fi
    chmod u+w nix_origin.bpf.c
  '';

  patchPhase = ''
    substituteInPlace nix_origin.bpf.c \
      --replace-fail \
        'extern int bpf_binprm_set_interp(' \
        'extern int bpf_binprm_set_flags(struct linux_binprm *bprm, enum bpf_binprm_flags flags) __ksym;
extern int bpf_binprm_set_interp(' \
      --replace-fail \
        'ret = bpf_binprm_set_interp(bprm, sc->path, rsz);' \
        'ret = bpf_binprm_set_flags(bprm, BPF_BINPRM_LOADER);
	if (!ret)
		ret = bpf_binprm_set_interp(bprm, sc->path, rsz);'
  '';

  buildPhase = ''
    bpftool btf dump file ${kernel.dev}/vmlinux format c > vmlinux.h
    clang -g -O2 -target bpf -D__TARGET_ARCH_x86 -I. -I${libbpf}/include \
      -c nix_origin.bpf.c -o nix_origin.bpf.o
  '';

  installPhase = ''
    install -Dm444 nix_origin.bpf.o $out/nix_origin.bpf.o
    install -Dm444 nix_origin.bpf.c $out/src/nix_origin.bpf.c
  '';
}
