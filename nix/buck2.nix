# buck2 outputs as Nix store paths.
#
# A buck2 output is named by its REAPI Directory digest. Its store path is a
# function of that digest and its name, computed identically by
# nix/publish.py, so neither side asks the other. Evaluation never runs
# buck2: fetchClosure asks the substituter for the pinned path.
{ substituter }:

rec {
  storePath = { name, digest }:
    let
      h = builtins.convertHash {
        hash = builtins.hashString "sha256" "buck2-reapi-directory:${digest}:${name}";
        hashAlgo = "sha256";
        toHashFormat = "nix32";
      };
    in "/nix/store/${builtins.substring 0 32 h}-${name}";

  # output { name = "hello"; digest = "<sha256>:<size>"; }
  output = { name, digest }:
    builtins.fetchClosure {
      fromStore = substituter;
      fromPath = storePath { inherit name digest; };
      inputAddressed = true;
    };
}
