{
  description = "One store, two frontends: relocatable Nix closures as buck2 toolchains";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/fe13242281a67641c0102cdb1087f0ebe586c7df";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      lib = nixpkgs.lib;

      # The relocator, and only it: its source is part of every relocated name.
      relocator = lib.fileset.toSource {
        root = ./nix;
        fileset = lib.fileset.unions [ ./nix/relocate.py ./nix/check-relocatable.py ./nix/storepath.py ];
      };

      # Copy the closure of `roots` (role -> package) into $out/nix/store, each
      # path renamed and made $ORIGIN-relative (see nix/relocate.py), and
      # refuse to produce it if anything still pins it to /nix/store or names
      # an original path. `originals` names the roots as cache.nixos.org has them.
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
      };
      gcc-closure = closures.gcc;
      remotetool = pkgs.callPackage ./nix/remotetool.nix { };

      # Upload the relocated closures to the REAPI CAS, pin their digests for
      # buck2 in nix_closures.bzl and index their store paths for the
      # substituter. Run from the repository root.
      push-closure = pkgs.writeShellApplication {
        name = "push-closure";
        runtimeInputs = [ remotetool pkgs.python3 ];
        text = ''
          exec python3 ${./nix}/push_closure.py nix_closures.bzl .nix-buck/index ${
            pkgs.writeText "closures.json" (builtins.toJSON
              (builtins.mapAttrs (_: c: { tree = "${c}"; inherit (c) originals; }) closures))}
        '';
      };

      python = pkgs.python3.withPackages (p: [ p.cryptography ]);

      # A Nix binary cache in front of the CAS: every indexed store path (the
      # relocated closures and published buck2 outputs) by digest. Keys and
      # the index live in .nix-buck/. Run from the repository root.
      substituter = pkgs.writeShellApplication {
        name = "substituter";
        runtimeInputs = [ python remotetool pkgs.nix ];
        text = ''
          mkdir -p .nix-buck/index
          if [ ! -e .nix-buck/secret-key ]; then
            nix key generate-secret --key-name nix-buck-1 > .nix-buck/secret-key
            nix key convert-secret-to-public < .nix-buck/secret-key > .nix-buck/public-key
          fi
          exec python3 ${./nix}/substituter.py --index .nix-buck/index \
            --secret-key .nix-buck/secret-key "$@"
        '';
      };

      # Build buck2 targets, index them for the substituter and pin their
      # digests in buck2-pins.json.
      publish = pkgs.writeShellApplication {
        name = "publish";
        runtimeInputs = [ pkgs.python3 remotetool pkgs.buck2 ];
        text = ''
          exec python3 ${./nix}/publish.py .nix-buck/index buck2-pins.json "$@"
        '';
      };

      # The gcc hello reports on: the original, which no machine here has.
      nixGcc = "/nix/store/${gcc-closure.originals.gcc}";

      buck2 = import ./nix/buck2.nix { substituter = "http://127.0.0.1:8090"; };
    in {
      lib.buck2 = buck2;

      packages.${system} = {
        inherit gcc-closure remotetool push-closure substituter publish;
        zlib-closure = closures.zlib;
        buck2 = pkgs.buck2;
        host-vm = self.nixosConfigurations.host.config.system.build.vm;
        default = gcc-closure;
        # Boot with dev/vm.sh worker.
        worker-vm = self.nixosConfigurations.worker.config.system.build.vm;
      };

      # Published buck2 outputs as store paths (`nix build .#hello`), pinned by
      # digest in buck2-pins.json, which `nix run .#publish` writes.
      # Evaluation never runs buck2; it asks the substituter. They are paths,
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

      # Boot the worker and compile hello on it with the relocated closure,
      # every tool exec'd directly through the $ORIGIN handler.
      checks.${system}.worker = pkgs.testers.runNixOSTest {
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
}
