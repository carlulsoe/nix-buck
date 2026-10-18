load("@rules//:closure.bzl", "nix_closure")
load("@rules//:cc.bzl", "cc_binary", "cc_library", "nix_cc_library", "nix_cc_toolchain", "run_remote")
load(":nix_closures.bzl", "NIX_CLOSURES")

# Relocated Nix closures, each pinned by digest as one tree artifact.
# nix_closures.bzl is written by `nix run .#push-closure`.
nix_closure(name = "gcc-closure", **NIX_CLOSURES["gcc"])

nix_closure(name = "zlib-closure", **NIX_CLOSURES["zlib"])

nix_cc_toolchain(name = "cc", closure = ":gcc-closure")

# zlib as nixpkgs built it.
nix_cc_library(
    name = "zlib",
    closure = ":zlib-closure",
    lib = "zlib",
    include = "zlib-dev",
    libs = ["z"],
)

cc_library(name = "report", srcs = ["src/report.c"], hdrs = ["src/report.h"])

cc_binary(name = "hello", srcs = ["src/hello.c"], deps = [":report"])

cc_binary(name = "zhello", srcs = ["src/zhello.c"], deps = [":report", ":zlib"])

# Run each binary on the worker and keep what it prints.
run_remote(name = "hello-report", exe = ":hello")

run_remote(name = "zhello-report", exe = ":zhello")
