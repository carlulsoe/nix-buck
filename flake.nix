{
  description = "One store, two frontends: relocatable Nix closures as buck2 toolchains";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/fe13242281a67641c0102cdb1087f0ebe586c7df";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      lib = nixpkgs.lib;

      # The relocator, and only it: its source is part of every relocated name.
      # Comment on its files here, not in them: editing them renames every
      # relocated path and changes the pins.
      relocator = lib.fileset.toSource {
        root = ./nix;
        fileset = lib.fileset.unions [ ./nix/relocate.py ./nix/check-relocatable.py ./nix/storepath.py ];
      };

      # Copy the closure of `roots` (role -> package) into $out/nix/store, each
      # path renamed and made $ORIGIN-relative (see nix/relocate.py), and
      # refuse to produce it if anything still pins it to /nix/store or names
      # an original path. `originals` names the roots as cache.nixos.org has them.
      #
      # Stand-in for the article's roadmap steps 1-3: nixpkgs building with
      # $ORIGIN loader paths, relocatable wrappers, and `relocatable = true`
      # enforced by a fixup hook (check-relocatable.py plays that hook).
      # Patching after the fact changes the bytes, so the paths must be renamed
      # and can never be cache.nixos.org's. Remove when nixpkgs builds these
      # roots relocatably: they are then used as they are, under their own
      # names, and `originals` goes with this.
      relocate = name: roots: pkgs.runCommand name {
        nativeBuildInputs = [ pkgs.python3 pkgs.patchelf ];
        __structuredAttrs = true;
        roots = builtins.mapAttrs (_: p: "${p}") roots;
        exportReferencesGraph.closure = builtins.attrValues roots;
        passthru.originals = builtins.mapAttrs
          (_: p: baseNameOf (builtins.unsafeDiscardStringContext "${p}")) roots;
      } ''
        python3 ${relocator}/relocate.py $out "${relocator} ${pkgs.patchelf}" "$NIX_ATTRS_JSON_FILE"
        python3 ${relocator}/check-relocatable.py $out "$NIX_ATTRS_JSON_FILE"
      '';

      # Every relocated closure buck2 builds with, named the way BUCK uses them.
      closures = {
        gcc = relocate "gcc-closure" {
          gcc = pkgs.gcc.cc;
          gcc-lib = pkgs.gcc.cc.lib;
          binutils = pkgs.binutils-unwrapped;
          glibc = pkgs.glibc;
          glibc-dev = pkgs.glibc.dev;
          linux-headers = pkgs.glibc.linuxHeaders;
        };
        zlib = relocate "zlib-closure" {
          zlib = pkgs.zlib;
          zlib-dev = pkgs.zlib.dev;
        };
        # A library with a deep closure: openssl, nghttp2/3, ngtcp2, brotli,
        # zstd, krb5, libssh2, libpsl, c-ares, and scripts with shebangs.
        curl = relocate "curl-closure" {
          curl = pkgs.curl.out;
          curl-dev = pkgs.curl.dev;
          # Already in curl's closure; roots so BUCK can name them.
          openssl = pkgs.openssl.out;
          openssl-dev = pkgs.openssl.dev;
          libpsl = pkgs.libpsl.out;
          libpsl-dev = pkgs.libpsl.dev;
        };
        # The shell actions run under: workers have none of their own.
        bash = relocate "bash-closure" { bash = pkgs.bash; };
      };
      gcc-closure = closures.gcc;
      remotetool = pkgs.callPackage ./nix/remotetool.nix { };

      # What push-closure and nix_closures.bzl are made from.
      closuresJson = pkgs.writeText "closures.json" (builtins.toJSON
        (builtins.mapAttrs (_: c: { tree = "${c}"; inherit (c) originals; }) closures));

      # nix_closures.bzl as it must be: every closure pinned by the REAPI
      # digest it will have in any CAS, computed here without one.
      closure-pins = pkgs.runCommand "nix_closures.bzl" { nativeBuildInputs = [ pkgs.python3 ]; } ''
        python3 ${lib.fileset.toSource {
          root = ./nix;
          fileset = lib.fileset.unions [ ./nix/pins.py ./nix/reapi.py ];
        }}/pins.py ${closuresJson} > $out
      '';

      # Install nix_closures.bzl and upload the closures to the REAPI CAS (the
      # CAS must agree with the pinned digests). Run from the repository root.
      push-closure = pkgs.writeShellApplication {
        name = "push-closure";
        runtimeInputs = [ remotetool pkgs.python3 ];
        text = ''
          install -m 644 ${closure-pins} nix_closures.bzl
          exec python3 ${./nix}/push_closure.py ${closuresJson}
        '';
      };

      # Build buck2 targets, add them and their closures to the static binary
      # cache in .nix-buck/cache, and pin their digests in buck2-pins.json.
      # Stand-in, with serve-cache, for Nix substituting from the REAPI CAS
      # itself, as the article's CAS-as-substituter does: the cache copies
      # out of the CAS what is already there. Remove when Nix can read a
      # store path from a REAPI CAS by digest (roadmap step 5).
      # The signing key is .nix-buck/secret-key; Nix needs .nix-buck/public-key.
      # Run from the repository root.
      publish = pkgs.writeShellApplication {
        name = "publish";
        runtimeInputs = [ (pkgs.python3.withPackages (p: [ p.cryptography ])) pkgs.buck2 pkgs.nix ];
        text = ''
          if [ ! -e .nix-buck/secret-key ]; then
            mkdir -p .nix-buck
            nix key generate-secret --key-name nix-buck-1 > .nix-buck/secret-key
            nix key convert-secret-to-public < .nix-buck/secret-key > .nix-buck/public-key
          fi
          exec python3 ${./nix}/publish.py .nix-buck/cache .nix-buck/secret-key \
            buck2-pins.json ${closuresJson} "$@"
        '';
      };

      # Serve the static cache over HTTP, which fetchClosure requires. Any
      # static file server does; in production, the bucket or CDN it is
      # copied to. Run from the repository root.
      serve-cache = pkgs.writeShellApplication {
        name = "serve-cache";
        runtimeInputs = [ pkgs.python3 ];
        text = ''
          exec python3 -m http.server --bind 0.0.0.0 --directory .nix-buck/cache 8090
        '';
      };

      # The gcc hello reports on: the original, which no machine here has.
      nixGcc = "/nix/store/${gcc-closure.originals.gcc}";

      # Where published outputs are read from: the cache publish writes, as
      # `nix run .#serve-cache` serves it. Wherever it is copied to, this is
      # that URL instead.
      buck2 = import ./nix/buck2.nix { cache = "http://127.0.0.1:8090"; };
    in {
      lib.buck2 = buck2;

      packages.${system} = {
        inherit gcc-closure closure-pins remotetool push-closure publish serve-cache;
        zlib-closure = closures.zlib;
        buck2 = pkgs.buck2;
        host-vm = self.nixosConfigurations.host.config.system.build.vm;
        default = gcc-closure;
        # Boot with dev/vm.sh worker.
        worker-vm = self.nixosConfigurations.worker.config.system.build.vm;
      };

      # Published buck2 outputs as store paths (`nix build .#hello`), pinned by
      # digest in buck2-pins.json, which `nix run .#publish` writes.
      # Evaluation never runs buck2; it reads the binary cache. They are paths,
      # not derivations, hence legacyPackages.
      legacyPackages.${system} = builtins.mapAttrs
        (name: digest: buck2.output { inherit name digest; })
        (lib.importJSON ./buck2-pins.json);

      nixosConfigurations.worker = nixpkgs.lib.nixosSystem {
        modules = [ ./nix/worker.nix { nixpkgs.hostPlatform = system; } ];
      };
      nixosConfigurations.host = nixpkgs.lib.nixosSystem {
        modules = [ ./nix/host.nix { nixpkgs.hostPlatform = system; } ];
      };

      checks.${system} = {
        # The committed pins are the closures the flake builds now.
        closure-pins = pkgs.runCommand "closure-pins-current" { } ''
          if ! diff -u ${./nix_closures.bzl} ${closure-pins}; then
            echo "nix_closures.bzl does not pin the flake's closures: run nix run .#push-closure" >&2
            exit 1
          fi
          touch $out
        '';

        # Boot the worker and compile hello on it with the relocated closure,
        # every tool exec'd directly through the $ORIGIN handler.
        worker = pkgs.testers.runNixOSTest {
          name = "nix-origin-worker";
          nodes.worker = { lib, ... }: {
            imports = [ ./nix/worker.nix ];
            virtualisation.additionalPaths = [ gcc-closure ];
            virtualisation.forwardPorts = lib.mkForce [ ];
          };
          testScript = ''
            import re
            worker.wait_for_unit("nix-origin-binfmt.service")
            worker.wait_for_unit("nativelink.service")
            worker.wait_for_open_port(50051)
            worker.succeed("uname -r | grep '^7\\.3'")
            print(worker.succeed("cat /proc/sys/fs/binfmt_misc/nix-origin"))
            out = worker.succeed("sh ${./tests/relocated-gcc.sh} ${gcc-closure} ${./src} ${nixGcc} 2>&1")
            print(out)
            assert "exec'ing tools directly" in out
            # Loader substitution: the binary, not ld.so, is the exec'd program.
            assert re.search(r"^/proc/self/exe: +/tmp/\S+/nix/store/hello/bin/hello$", out, re.M)
            assert "${nixGcc} on this machine: absent" in out
          '';
        };
      };
    };
}
