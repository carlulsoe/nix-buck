{
  description = "One store, two frontends: relocatable Nix closures as buck2 toolchains";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/fe13242281a67641c0102cdb1087f0ebe586c7df";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      # The toolchain roots, named the way the buck2 toolchain refers to them.
      gccRoots = {
        gcc = pkgs.gcc.cc;
        gcc-lib = pkgs.gcc.cc.lib;
        binutils = pkgs.binutils-unwrapped;
        glibc = pkgs.glibc;
        glibc-dev = pkgs.glibc.dev;
        linux-headers = pkgs.glibc.linuxHeaders;
      };

      # Copy a closure into $out/nix/store with every loader path made
      # $ORIGIN-relative, and refuse to produce it if anything still pins it.
      relocatableClosure = name: roots:
        let info = pkgs.closureInfo { rootPaths = builtins.attrValues roots; };
        in pkgs.runCommand name {
          nativeBuildInputs = [ pkgs.python3 pkgs.patchelf ];
          roots = builtins.mapAttrs (_: p: baseNameOf p) roots;
          # The copies still embed original store paths in strings the
          # checker allows (spec strings, configure defaults). They are not
          # dependencies: the tree is self-contained, so do not let the
          # reference scanner pull the unrelocated originals in after it.
          __structuredAttrs = true;
          unsafeDiscardReferences.out = true;
        } ''
          python3 ${./nix/relocate.py} $out $(cat ${info}/store-paths)
          python3 ${./nix/check-relocatable.py} $out
          python3 - ${info}/store-paths "$NIX_ATTRS_JSON_FILE" > $out/closure.json <<'EOF'
          import json, os, sys
          paths = [os.path.basename(p) for p in open(sys.argv[1]).read().split()]
          roots = json.load(open(sys.argv[2]))["roots"]
          print(json.dumps({"roots": roots, "paths": sorted(paths)}, indent=2))
          EOF
        '';
      gcc-closure = relocatableClosure "gcc-closure" gccRoots;
    in {
      packages.${system} = {
        inherit gcc-closure;
        default = gcc-closure;
        # Boot with: QEMU_NET_OPTS=... result/bin/run-nix-origin-worker-vm
        worker-vm = self.nixosConfigurations.worker.config.system.build.vm;
      };

      nixosConfigurations.worker = nixpkgs.lib.nixosSystem {
        modules = [ ./nix/worker.nix { nixpkgs.hostPlatform = system; } ];
      };

      # Boot the worker and compile hello.c on it with the relocated closure,
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
          out = worker.succeed("sh ${./tests/relocated-gcc.sh} ${gcc-closure} ${./hello.c} 2>&1")
          print(out)
          assert "exec'ing tools directly" in out
          # Loader substitution: the binary, not ld.so, is the exec'd program.
          assert re.search(r"^/proc/self/exe: +/tmp/\S+/nix/store/hello/bin/hello$", out, re.M)
          assert "-gcc-16.2.0 on this machine: absent" in out
        '';
      };
    };
}
