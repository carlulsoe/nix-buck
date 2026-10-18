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
          rootsJson = builtins.toJSON (builtins.mapAttrs (_: p: baseNameOf p) roots);
          passAsFile = [ "rootsJson" ];
        } ''
          python3 ${./nix/relocate.py} $out $(cat ${info}/store-paths)
          python3 ${./nix/check-relocatable.py} $out
          python3 - ${info}/store-paths $rootsJsonPath > $out/closure.json <<'EOF'
          import json, os, sys
          paths = [os.path.basename(p) for p in open(sys.argv[1]).read().split()]
          print(json.dumps({"roots": json.load(open(sys.argv[2])), "paths": sorted(paths)}, indent=2))
          EOF
        '';
    in {
      packages.${system} = {
        gcc-closure = relocatableClosure "gcc-closure" gccRoots;
        default = self.packages.${system}.gcc-closure;
      };
    };
}
