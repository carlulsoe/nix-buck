# buck2 outputs as Nix store paths.
#
# A buck2 output is named by its REAPI Directory digest. Its store path is a
# function of that digest and its name, computed identically by
# nix/publish.py, so neither side asks the other. Evaluation never runs
# buck2: fetchClosure reads the pinned path from the binary cache publish
# writes.
#
# Stand-in for the article's roadmap step 5, a Nix content-addressing method
# that is the REAPI Directory digest. Until then the digest is hashed into an
# input-addressed path, which only a key Nix trusts can vouch for. Remove when
# Nix has the method: the store path is then content-addressed by the digest,
# and publish.py's store_path goes too.
{ cache }:

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
      fromStore = cache;
      fromPath = storePath { inherit name digest; };
      inputAddressed = true;
    };
}
