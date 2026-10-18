load(":closure.bzl", "NixClosureInfo", "store_path")

NixCcToolchainInfo = provider(fields = {
    "closure": provider_field(typing.Any),
})

# Shaped like a store path for Nix: the package directory, its name, and the
# store paths it refers to (the ones put in its RUNPATH and PT_INTERP).
NixStorePathInfo = provider(fields = {
    "name": provider_field(str),
    "out": provider_field(typing.Any),
    "references": provider_field(list[str]),
})

_ROLES = ["gcc", "gcc-lib", "binutils", "glibc", "glibc-dev", "linux-headers"]
_TRIPLE = "x86_64-unknown-linux-gnu"
_LOADER = "ld-linux-x86-64.so.2"

# Runtime store paths every binary links against.
_RUNTIME = ["glibc", "gcc-lib"]

def _nix_cc_toolchain_impl(ctx: AnalysisContext) -> list[Provider]:
    closure = ctx.attrs.closure[NixClosureInfo]
    for role in _ROLES:
        if role not in closure.roots:
            fail("closure has no `{}` root".format(role))
    return [DefaultInfo(), NixCcToolchainInfo(closure = closure)]

nix_cc_toolchain = rule(
    impl = _nix_cc_toolchain_impl,
    attrs = {"closure": attrs.dep(providers = [NixClosureInfo])},
)

def _gcc(closure: NixClosureInfo) -> cmd_args:
    return cmd_args(
        store_path(closure, "gcc", "bin/gcc"),
        # as and ld come from binutils, never from the worker's PATH.
        cmd_args(store_path(closure, "binutils", "bin"), format = "-B{}/"),
        # The whole tree is an input: cc1, as and ld load libraries from siblings.
        hidden = closure.tree,
    )

def _compile_flags(closure: NixClosureInfo) -> cmd_args:
    gcc_version = closure.roots["gcc"].split("-gcc-")[1]
    gcc_inc = "lib/gcc/{}/{}/".format(_TRIPLE, gcc_version)
    return cmd_args(
        # Only headers from the closure, never from the machine compiling.
        "-nostdinc",
        cmd_args(store_path(closure, "gcc", gcc_inc + "include"), format = "-isystem{}"),
        cmd_args(store_path(closure, "gcc", gcc_inc + "include-fixed"), format = "-isystem{}"),
        cmd_args(store_path(closure, "glibc-dev", "include"), format = "-isystem{}"),
        cmd_args(store_path(closure, "linux-headers", "include"), format = "-isystem{}"),
        # Where gcc "is", as far as Nix is concerned; hello.c reports on it.
        '-DNIX_GCC="/nix/store/{}"'.format(closure.roots["gcc"]),
    )

def _link_flags(closure: NixClosureInfo) -> cmd_args:
    # The binary lands at nix/store/<name>/bin/<name>, so its runtime
    # dependencies are two directories up, beside its own package.
    def sibling(role, subpath):
        return "$ORIGIN/../../{}/{}".format(closure.roots[role], subpath)

    return cmd_args(
        cmd_args(store_path(closure, "glibc", "lib"), format = "-B{}/"),
        cmd_args(store_path(closure, "glibc", "lib"), format = "-L{}"),
        cmd_args(store_path(closure, "gcc-lib", "lib"), format = "-L{}"),
        "-Wl,--dynamic-linker=" + sibling("glibc", "lib/" + _LOADER),
        "-Wl,-rpath," + ":".join([sibling(role, "lib") for role in _RUNTIME]),
    )

def _cc_binary_impl(ctx: AnalysisContext) -> list[Provider]:
    closure = ctx.attrs.toolchain[NixCcToolchainInfo].closure
    name = ctx.attrs.name

    objs = []
    for src in ctx.attrs.srcs:
        obj = ctx.actions.declare_output("objs", src.short_path + ".o")
        ctx.actions.run(
            cmd_args(_gcc(closure), "-c", _compile_flags(closure), ctx.attrs.copts, "-o", obj.as_output(), src),
            category = "cc_compile",
            identifier = src.short_path,
        )
        objs.append(obj)

    linked = ctx.actions.declare_output(name + ".linked")
    ctx.actions.run(
        cmd_args(_gcc(closure), _link_flags(closure), objs, "-o", linked.as_output()),
        category = "cc_link",
    )

    # root/nix/store/<name>/bin/<name>, as mkDerivation would lay it out,
    # with the runtime closure symlinked in beside it so the relative loader
    # paths resolve. Fixed (not content-based) output paths keep the separate
    # artifacts siblings. The binary itself must be a real file: $ORIGIN is
    # where the kernel finds it.
    store = "root/nix/store/"
    out = ctx.actions.copied_dir(
        ctx.actions.declare_output(store + name, dir = True, has_content_based_path = False),
        {"bin/" + name: linked},
    )
    runtime = [
        ctx.actions.symlink_file(
            ctx.actions.declare_output(store + closure.roots[role], has_content_based_path = False),
            store_path(closure, role),
        )
        for role in _RUNTIME
    ]
    exe = out.project("bin/" + name)

    # What Nix needs besides the bytes: the name and the references, known
    # here because this rule put them in RUNPATH. `nix run .#publish` pairs
    # it with the output's digest; that pair is the narinfo.
    store = NixStorePathInfo(
        name = name,
        out = out,
        references = [closure.roots[role] for role in _RUNTIME],
    )
    meta = ctx.actions.write_json(name + ".nix.json", {"name": store.name, "references": store.references})

    return [
        DefaultInfo(default_output = out, sub_targets = {"nix": [DefaultInfo(default_output = meta)]}),
        RunInfo(args = cmd_args(exe, hidden = runtime)),
        store,
    ]

cc_binary = rule(
    impl = _cc_binary_impl,
    attrs = {
        "srcs": attrs.list(attrs.source()),
        "copts": attrs.list(attrs.string(), default = []),
        "toolchain": attrs.dep(default = "root//:cc", providers = [NixCcToolchainInfo]),
    },
)

def _run_remote_impl(ctx: AnalysisContext) -> list[Provider]:
    report = ctx.actions.declare_output(ctx.attrs.name + ".txt")
    ctx.actions.run(
        cmd_args("/bin/sh", "-c", '"$@" > "$0"', report.as_output(), ctx.attrs.exe[RunInfo]),
        category = "run_remote",
    )
    return [
        DefaultInfo(default_output = report),
        RunInfo(args = cmd_args("cat", report)),
    ]

# Run a binary on a worker and keep what it prints.
run_remote = rule(
    impl = _run_remote_impl,
    attrs = {"exe": attrs.dep(providers = [RunInfo])},
)
