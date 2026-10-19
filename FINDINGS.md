# Findings from reproducing "One store, two frontends"

This repository reproduces the design in Farid Zakaria's
[One store, two frontends](https://fzakaria.com/2026/10/17/one-store-two-frontends)
(2026-10-17). It uses the article's nixpkgs pin: the store hashes and the
17-path gcc closure match the article's. This document records what the
reproduction found that the article does not say, and where the repository
departs from the article because upstream work does not exist yet.

## What was reproduced

- A gcc/binutils/glibc closure with `$ORIGIN`-relative `PT_INTERP`,
  `RUNPATH` and symlinks. A check rejects it if anything still pins it to
  `/nix/store`.
- A NixOS worker VM on Linux 7.3-rc7. It registers the in-tree
  `nix_origin.bpf.c` handler at boot and runs NativeLink. Its store holds
  only its own system closure: it has no Nix and no compiler.
- buck2 rules (`nix_closure`, `nix_cc_toolchain`, `cc_binary`,
  `cc_library`, `nix_cc_library`, `run_remote`) with no prelude. Every
  action runs remotely. The toolchain is declared by its REAPI digest and
  is never downloaded.
- buck2 outputs substituted back into a Nix store by their pinned digest,
  and run natively on a Linux 7.3 Nix host.

`tests/step1.sh`, `tests/step3.sh`, `tests/step4.sh` and `nix flake check`
cover each stage.

## Findings

### Hermetic builds need a sandbox, even when the worker has no Nix

The article says workers need no Nix install, NFS or chroot. That holds for
*running* relocated binaries. It does not make the build *hermetic*.

- **What an action could see.** Without a sandbox, a NativeLink action could
  see the worker's store, `/bin/sh`, `/etc`, NativeLink's own CAS and action
  cache, and the network. Anything it read from those leaks silently into
  cached results.
- **Capabilities.** NativeLink runs as root, so a first bubblewrap sandbox
  kept root's capabilities: the probe saw `CapEff 000001ffffffffff` and
  `mount` succeeded. `--cap-drop ALL` fixed it (`8e0908f`).
- **The worker's shell is off limits.** Inside the sandbox an action has no
  `/bin/sh`, so `run_remote` needs a shell shipped as an input: a relocated
  bash closure (`7bff3c9`).

`src/probe.c`, run remotely by `tests/step3.sh`, asserts all of this. The
sandbox (`nix/worker.nix`) knows nothing about Nix. A production remote
execution setup needs one anyway, so "no chroot" does not save a worker as
much configuration as it suggests.

### Relocating existing nixpkgs output forces new store-path names

The article's roadmap gets relocatable output from nixpkgs itself, so
"no cache is invalidated". The reproduction cannot rebuild nixpkgs, so it
patches cache.nixos.org's output (patchelf plus hash rewriting). The patched
bytes differ from the originals, so keeping the original names would put two
contents under one store path. Each relocated path is therefore renamed from
its original name and a salt that identifies the relocator (`7c0a7ad`). Every
original hash is rewritten, same length, as Nix rewrites hashes. A path
relocates to the same name and bytes in every closure: glibc is identical in
the gcc and zlib closures.

Some details any relocation step, including a nixpkgs fixup hook, will hit:

- **Nix finds references in entry names too.** A hash in a file or directory
  name is a reference. The scanner has to read names, as Nix's NAR scan does
  (`c210388`).
- **Dead `RUNPATH` entries.** nixpkgs leaves some, such as scrubbed
  `/nix/store/eeee…` references. They name nothing in the closure and must be
  dropped, not relocated.
- **Leftover `/nix/store` strings.** Other `/nix/store` strings (spec
  strings, configure-time defaults) do not stop a binary loading. But until
  they were rewritten, Nix's reference scanner pulled the original gcc back
  into the closure (`1c70993`).
- **The cc-wrapper's flags move into the build rule.** The cc-wrapper's
  work has to be redone by the rule: `-nostdinc` and explicit `-isystem`
  paths, `-B` for binutils and glibc, `--dynamic-linker` and `RUNPATH` as
  `$ORIGIN/../../<store path>`. nixpkgs-specific link inputs such as
  `-lgcc_s_asneeded` have to resolve inside the closure. This is the
  article's roadmap step 2, and `rules/cc.bzl` is a worked example of what
  it must produce.

### The in-tree kernel handler needs one change to match the article's output

`tools/testing/selftests/exec/nix_origin.bpf.c` uses classic dispatch, so
`/proc/self/exe` names `ld.so`. The article's output shows the binary
itself, which needs loader substitution. That is one added
`bpf_binprm_set_flags(bprm, BPF_BINPRM_LOADER)` call
(`nix/nix-origin-bpf.nix`). The handler is root-registered, per-boot state:
every machine that runs relocated binaries needs it registered, not just
remote execution workers.

### buck2 constraints the rules have to work around

- **CAS TTLs.** OSS buck2's REAPI client cannot extend CAS TTLs. A
  `cas_artifact` whose declared expiry is later than `cas_ttl_secs` makes
  buck2 try, and fail. The rules declare `expires_after_timestamp = 0` and
  rely on `push-closure` re-uploading.
- **A closure has to stay one artifact.** `copied_dir` rewrites relative
  symlinks, so `bin/ld -> ld.bfd` came to point back at the source artifact.
  It also drops entries copied from a projection of a `cas_artifact` from the
  tree it sends to remote execution. So a closure is one artifact, store paths
  are projections of it, and a binary's runtime store paths are symlinks laid
  out beside it.
- **Sibling layouts need fixed output paths.** Content-based output paths
  do not keep separately declared artifacts as siblings. The output layout
  `nix/store/<name>` plus its runtime paths needs
  `has_content_based_path = False`.

### A REAPI digest depends on how the tree was uploaded

The article's roadmap step 5 is a Nix content-addressing method that *is*
the REAPI Directory digest. The reproduction computes those digests locally
(`nix/reapi.py`) and checks them against the CAS. That check caught
`remotetool` lexically cleaning relative symlink targets on upload: ncurses'
`.././z/z100` was stored as `z100`, so the CAS held a different tree, under
a different digest, from the store path it came from (`7bff3c9`). The
relocator now emits cleaned targets. A Nix method keyed on REAPI digests
has to specify that normalisation, or uploaders and Nix will disagree.

Computing digests locally pays off in another way too. Nix generates the
buck2 pins (`nix_closures.bzl`), and `nix flake check` fails when the
committed copy is stale. The pins and the CAS can no longer drift apart
silently.

### A closure is a layout for the loader, not for compiled-in paths

`curlhello` (`src/curlhello.cc`) is C++ linked against nixpkgs' libcurl.
The relocated closure is 47 store paths and 85 MiB, with openssl, nghttp2/3,
ngtcp2, brotli, zstd, krb5, libssh2, libpsl and c-ares. The ELF side
relocated without a change to the relocator: 426 images, every `PT_INTERP`
and `RUNPATH` `$ORIGIN`-relative. `g++` and libstdc++ from the existing gcc
closure needed only rule changes (`rules/cc.bzl`): the libstdc++ include
directories, and linking with `g++` when anything in the binary is C++. On
the worker, libcurl and its transitive libraries load through `$ORIGIN`.

What does not relocate is any absolute path that a library computes and
opens itself. The relocator rewrites the hash, so the path names the
relocated store path, but it is still `/nix/store/...`:

| Library | Compiled-in path | On the worker | From a Nix store |
|---|---|---|---|
| libpsl | the public suffix list, in another store path | absent: silently falls back to its built-in list | present |
| OpenSSL | `MODULESDIR` (providers), `OPENSSLDIR` (config, certs) | absent: the legacy provider does not load | present, loads |
| krb5 | plugin directories, `krb5.conf`, locale | not exercised | |
| scripts | shebangs (`curl-config`, `krb5-config`) | not exercised; cannot run | |

These come from the same binary, run by `tests/step3.sh` on the worker and
by its own loader from a store that `fetchClosure` filled. A worker gets the
right libraries and quietly different behaviour. `check-relocatable.py` saw
all of these: they are among the 232 files it lists as informational. A
fixup hook for `relocatable = true` (roadmap step 3) has to decide what to
do about them. It could make them `$ORIGIN`-relative at the source, where
the library supports that (OpenSSL can locate providers relative to
libcrypto), or fail.

### Linking and running need whole closures, not projections

A library's `$ORIGIN` RUNPATH works at link time too. GNU ld expands
`$ORIGIN` in a library's RUNPATH (binutils 2.28 and later) to find the
libraries it needs, so the cc-wrapper's job needs no `-rpath-link`. But a
store path handed to an action as a projection of the closure (`-L
<curl>/lib`) sends only that subtree, so the libraries libcurl needs were
missing from the link. At run time the same thing happens one level down. A
binary's runtime store paths are symlinks into their closure trees, and the
kernel resolves a library's `$ORIGIN/../..` through the link, inside that
library's own closure. That closure must be there whole. A store path that
two closures share is laid out once beside the binary, so the other
closure's copy is never sent. The link and run actions now take every
closure they use whole.

In that VM, with a warm local CAS, materialising inputs took about 190 ms
for curlhello's link against 75–90 ms for the C binaries. It took about
180 ms for every run action, which now carries the gcc tree as well. The
C++ compile took 412 ms against about 35 ms for C.

### A C++ binary at `-O0` refers to its compiler

GCC 15 and later define `_GLIBCXX_ASSERTIONS` by default when not
optimising, and the rules pass no `-O`. libstdc++'s assertion messages embed
`__FILE__` of its headers, so the binary names the gcc store path (here as
a `buck-out` path) and Nix's scan makes all of gcc a runtime dependency:
curlhello's closure is 28 store paths and 362 MiB. Nix behaves the same way
for an `-O0` C++ build. The rules leave it as it is: removing the reference
would mean dropping the assertions or rewriting the path.

### `fetchClosure` reads only http(s) stores

A buck2 output reaches Nix as `builtins.fetchClosure` of a pinned path.
`fetchClosure` rejects `file://` stores, so even a static cache needs an
HTTP server (`nix run .#serve-cache`, or any bucket or CDN).

## Where the repository departs from the article

Each stand-in is marked in place with its removal condition; `grep -rni
Stand-in` finds them.

| Article | Repository | Retired by |
|---|---|---|
| nixpkgs builds relocatable output (roadmap 1–3) | `relocate` in `flake.nix`: patches cache.nixos.org output after the fact, renames paths; `check-relocatable.py` plays the fixup hook | nixpkgs building these roots relocatably |
| Nix content-addresses by REAPI digest (roadmap 5) | `nix/buck2.nix` hashes the digest into an input-addressed path, trusted by signing key | Nix gaining that method |
| The CAS is Nix's substituter | `publish` copies outputs and closures into a static signed binary cache | Nix reading store paths from a REAPI CAS |
| A NixOS module registers the handler (roadmap 4) | `nix/origin.nix`, on `linuxPackages_testing`, with the loader-substitution patch | That module, and 7.3 released |

The static cache replaced an earlier stand-in for the third row: a small
HTTP substituter that served NARs out of the CAS on demand (`0d1d5ca`).
It was dropped for operational reasons. It was a live single-process
service that held NARs in memory, with the signing key on a development
machine. The static cache is plain files with nothing to run. The cost is
that output bytes are copied out of the CAS instead of served from it. When
Nix can read the CAS itself, both go away.

## Not covered

- curlhello on the Nix host VM. `tests/step4.sh` publishes hello and
  zhello only. curlhello was published, substituted with `fetchClosure` and
  run by its loader in the dev container, a 7.2 kernel without the handler.
- Running the scripts in a closure, and krb5's compiled-in paths.
- A buck2-built shared library loaded by a buck2-built binary. `cc_library`
  is static only, and `publish` looks for references only among relocated
  Nix closures.
- A buck2 output fed back to buck2 as a toolchain or library.
- Cache-hit rates and the cost of a closure as an input to every action at
  real scale.
- The overhead of the BPF handler.
