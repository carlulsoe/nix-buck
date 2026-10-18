# remotetool from the Bazel remote-apis SDK: upload a directory tree to a
# REAPI CAS and get its root Directory digest, or download one by digest.
{ buildGoModule, fetchFromGitHub }:

buildGoModule {
  pname = "remotetool";
  version = "0-unstable-2026-10-16";
  src = fetchFromGitHub {
    owner = "bazelbuild";
    repo = "remote-apis-sdks";
    rev = "0e08b587cfaf303e42652ce2f25b57c537027365";
    hash = "sha256-kyYRcR42g6uhdP2jalZt1nBZH4bFT1A+MXbE0rCalGo=";
  };
  vendorHash = "sha256-FQzw8CyVkdf1B59roEB9YCZJ4EmIO28zqVulvDLHxRk=";
  subPackages = [ "go/cmd/remotetool" ];
  doCheck = false;
}
