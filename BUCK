load("@rules//:closure.bzl", "nix_closure")
load("@rules//:cc.bzl", "cc_binary", "nix_cc_toolchain", "run_remote")
load(":gcc_closure.bzl", "GCC_CLOSURE")

# The relocated gcc closure, pinned by digest, as one tree artifact.
# gcc_closure.bzl is written by `nix run .#push-closure`.
nix_closure(
    name = "closure",
    digest = GCC_CLOSURE["digest"],
    roots = GCC_CLOSURE["roots"],
    closure = GCC_CLOSURE["closure"],
)

nix_cc_toolchain(name = "cc", closure = ":closure")

cc_binary(name = "hello", srcs = ["hello.c"])

# Run the binary on the worker and keep what it prints.
run_remote(name = "hello-report", exe = ":hello")


