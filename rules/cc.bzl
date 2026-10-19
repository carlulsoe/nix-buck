load(":closure.bzl", "NixClosureInfo", "requisites", "store_path", "store_path_of")

NixCcToolchainInfo = provider(fields = {
    "closure": provider_field(typing.Any),
})

# What a C library gives what depends on it, whether buck2 built it
# (cc_library) or Nix did (nix_cc_library).
NixCcInfo = provider(fields = {
    # Header search flags.
    "compile": provider_field(typing.Any),
    # Archives and -L/-l flags, in link order.
    "link": provider_field(typing.Any),
    # Shared libraries loaded at run time: store paths in relocated closures,
    # struct(closure, base). Each one's lib/ goes in RUNPATH.
    "runtime": provider_field(list[typing.Any]),
    # Every closure involved: a binary's references are among their paths.
    "closures": provider_field(list[typing.Any]),
    # Whether any of it is C++, so the binary links with g++ (libstdc++).
    "cxx": provider_field(bool),
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

_CXX_EXTS = [".cc", ".cpp", ".cxx"]

def _is_cxx(src: Artifact) -> bool:
    return src.extension in _CXX_EXTS

def _gcc(closure: NixClosureInfo, cxx: bool) -> cmd_args:
    return cmd_args(
        store_path(closure, "gcc", "bin/g++" if cxx else "bin/gcc"),
        # as and ld come from binutils, never from the worker's PATH.
        cmd_args(store_path(closure, "binutils", "bin"), format = "-B{}/"),
        # The whole tree is an input: cc1, as and ld load libraries from siblings.
        hidden = closure.tree,
    )

def _compile_flags(closure: NixClosureInfo, cxx: bool) -> cmd_args:
    gcc_version = closure.roots["gcc"].split("-gcc-")[1]
    gcc_inc = "lib/gcc/{}/{}/".format(_TRIPLE, gcc_version)
    cxx_inc = "include/c++/" + gcc_version
    return cmd_args(
        # Only headers from the closure, never from the machine compiling.
        "-nostdinc",
        # libstdc++'s headers come first: they #include_next the C ones.
        [
            cmd_args(store_path(closure, "gcc", cxx_inc + sub), format = "-isystem{}")
            for sub in ["", "/" + _TRIPLE, "/backward"]
        ] if cxx else [],
        cmd_args(store_path(closure, "gcc", gcc_inc + "include"), format = "-isystem{}"),
        cmd_args(store_path(closure, "gcc", gcc_inc + "include-fixed"), format = "-isystem{}"),
        cmd_args(store_path(closure, "glibc-dev", "include"), format = "-isystem{}"),
        cmd_args(store_path(closure, "linux-headers", "include"), format = "-isystem{}"),
        # The gcc that nixpkgs has, which src/report.c looks for on the
        # machine it runs on. Not the relocated one: naming that would make
        # it a reference of every binary, as it would be in Nix.
        '-DNIX_GCC="/nix/store/{}"'.format(closure.originals["gcc"]),
    )

def _link_flags(closure: NixClosureInfo, runtime: list[typing.Any]) -> cmd_args:
    # The binary lands at nix/store/<name>/bin/<name>, so the store paths it
    # loads from are two directories up, beside its own.
    def sibling(base, subpath):
        return "$ORIGIN/../../{}/{}".format(base, subpath)

    return cmd_args(
        cmd_args(store_path(closure, "glibc", "lib"), format = "-B{}/"),
        cmd_args(store_path(closure, "glibc", "lib"), format = "-L{}"),
        cmd_args(store_path(closure, "gcc-lib", "lib"), format = "-L{}"),
        "-Wl,--dynamic-linker=" + sibling(closure.roots["glibc"], "lib/" + _LOADER),
        "-Wl,-rpath," + ":".join([sibling(r.base, "lib") for r in runtime]),
    )

def _merge(deps: list[Dependency]) -> NixCcInfo:
    infos = [d[NixCcInfo] for d in deps]
    return NixCcInfo(
        compile = cmd_args([i.compile for i in infos]),
        link = cmd_args([i.link for i in infos]),
        runtime = [r for i in infos for r in i.runtime],
        closures = [c for i in infos for c in i.closures],
        cxx = any([i.cxx for i in infos]),
    )

def _compile(ctx: AnalysisContext, closure: NixClosureInfo, flags: cmd_args) -> list[Artifact]:
    objs = []
    for src in ctx.attrs.srcs:
        obj = ctx.actions.declare_output("objs", src.short_path + ".o")
        cxx = _is_cxx(src)
        ctx.actions.run(
            cmd_args(_gcc(closure, cxx), "-c", _compile_flags(closure, cxx), flags, "-o", obj.as_output(), src),
            category = "cc_compile",
            identifier = src.short_path,
        )
        objs.append(obj)
    return objs

def _cc_library_impl(ctx: AnalysisContext) -> list[Provider]:
    closure = ctx.attrs.toolchain[NixCcToolchainInfo].closure
    deps = _merge(ctx.attrs.deps)
    include = ctx.actions.copied_dir("include", {h.basename: h for h in ctx.attrs.hdrs})
    compile = cmd_args(cmd_args(include, format = "-I{}"), deps.compile)
    objs = _compile(ctx, closure, cmd_args(compile, ctx.attrs.copts))

    archive = ctx.actions.declare_output("lib{}.a".format(ctx.attrs.name))
    ctx.actions.run(
        cmd_args(
            store_path(closure, "binutils", "bin/ar"),
            "rcsD",
            archive.as_output(),
            objs,
            hidden = closure.tree,
        ),
        category = "cc_archive",
    )
    return [
        DefaultInfo(default_output = archive),
        NixCcInfo(
            compile = compile,
            link = cmd_args(archive, deps.link),
            runtime = deps.runtime,
            closures = deps.closures,
            cxx = deps.cxx or any([_is_cxx(s) for s in ctx.attrs.srcs]),
        ),
    ]

# A static library built by buck2. Its headers are included by basename.
# Sources ending in .cc, .cpp or .cxx are C++.
cc_library = rule(
    impl = _cc_library_impl,
    attrs = {
        "srcs": attrs.list(attrs.source()),
        "hdrs": attrs.list(attrs.source(), default = []),
        "deps": attrs.list(attrs.dep(providers = [NixCcInfo]), default = []),
        "copts": attrs.list(attrs.string(), default = []),
        "toolchain": attrs.dep(default = "root//:cc", providers = [NixCcToolchainInfo]),
    },
)

def _nix_cc_library_impl(ctx: AnalysisContext) -> list[Provider]:
    closure = ctx.attrs.closure[NixClosureInfo]
    return [
        DefaultInfo(),
        NixCcInfo(
            compile = cmd_args(store_path(closure, ctx.attrs.include, "include"), format = "-isystem{}"),
            link = cmd_args(
                cmd_args(store_path(closure, ctx.attrs.lib, "lib"), format = "-L{}"),
                ["-l" + lib for lib in ctx.attrs.libs],
            ),
            runtime = [struct(closure = closure, base = closure.roots[ctx.attrs.lib])],
            closures = [closure],
            cxx = False,
        ),
    ]

# A shared library Nix built, from a relocated closure: headers in the
# `include` root's include/, libraries in the `lib` root's lib/.
nix_cc_library = rule(
    impl = _nix_cc_library_impl,
    attrs = {
        "closure": attrs.dep(providers = [NixClosureInfo]),
        "lib": attrs.string(),
        "include": attrs.string(),
        "libs": attrs.list(attrs.string()),
    },
)

def _cc_binary_impl(ctx: AnalysisContext) -> list[Provider]:
    closure = ctx.attrs.toolchain[NixCcToolchainInfo].closure
    name = ctx.attrs.name
    deps = _merge(ctx.attrs.deps)
    objs = _compile(ctx, closure, cmd_args(deps.compile, ctx.attrs.copts))

    runtime = {}
    for r in [struct(closure = closure, base = closure.roots[role]) for role in _RUNTIME] + deps.runtime:
        runtime.setdefault(r.base, r)
    runtime = runtime.values()

    cxx = deps.cxx or any([_is_cxx(s) for s in ctx.attrs.srcs])
    linked = ctx.actions.declare_output(name + ".linked")
    ctx.actions.run(
        cmd_args(
            _gcc(closure, cxx),
            _link_flags(closure, runtime),
            objs,
            deps.link,
            "-o",
            linked.as_output(),
            # ld follows each library's $ORIGIN RUNPATH to the libraries it
            # needs, so their whole closures are inputs, not just lib/.
            hidden = [c.tree for c in deps.closures],
        ),
        category = "cc_link",
    )

    # root/nix/store/<name>/bin/<name>, as mkDerivation would lay it out,
    # with every store path it loads from symlinked in beside it so the
    # relative loader paths resolve. Fixed (not content-based) output paths
    # keep the separate artifacts siblings. The binary itself must be a real
    # file: $ORIGIN is where the kernel finds it.
    store = "root/nix/store/"
    out = ctx.actions.copied_dir(
        ctx.actions.declare_output(store + name, dir = True, has_content_based_path = False),
        {"bin/" + name: linked},
    )
    siblings = {}
    for r in runtime:
        for base in requisites(r.closure, [r.base]):
            if base not in siblings:
                siblings[base] = ctx.actions.symlink_file(
                    ctx.actions.declare_output(store + base, has_content_based_path = False),
                    store_path_of(r.closure, base),
                )
    exe = out.project("bin/" + name)

    # What Nix needs besides the bytes: the store name, and the store paths
    # the output may refer to. `nix run .#publish` finds which it does by
    # scanning, and pairs that with the output's digest: the narinfo.
    candidates = {}
    for c in [closure] + deps.closures:
        for base in c.references:
            candidates[base] = True
    meta = ctx.actions.write_json(name + ".nix.json", {"name": name, "candidates": sorted(candidates)})

    return [
        DefaultInfo(default_output = out, sub_targets = {"nix": [DefaultInfo(default_output = meta)]}),
        # The siblings link into their closures' trees, and a library's
        # $ORIGIN/../.. resolves through the link, inside its own closure:
        # those trees are needed whole.
        RunInfo(args = cmd_args(exe, hidden = siblings.values() + [r.closure.tree for r in runtime])),
    ]

cc_binary = rule(
    impl = _cc_binary_impl,
    attrs = {
        "srcs": attrs.list(attrs.source()),
        "deps": attrs.list(attrs.dep(providers = [NixCcInfo]), default = []),
        "copts": attrs.list(attrs.string(), default = []),
        "toolchain": attrs.dep(default = "root//:cc", providers = [NixCcToolchainInfo]),
    },
)

def _run_remote_impl(ctx: AnalysisContext) -> list[Provider]:
    report = ctx.actions.declare_output(ctx.attrs.name + ".txt")
    shell = ctx.attrs.shell[NixClosureInfo]
    ctx.actions.run(
        cmd_args(
            store_path(shell, "bash", "bin/bash"),
            "-c",
            '"$@" > "$0"',
            report.as_output(),
            ctx.attrs.exe[RunInfo],
            hidden = shell.tree,
        ),
        category = "run_remote",
    )
    return [
        DefaultInfo(default_output = report),
        RunInfo(args = cmd_args("cat", report)),
    ]

# Run a binary on a worker and keep what it prints.
run_remote = rule(
    impl = _run_remote_impl,
    attrs = {
        "exe": attrs.dep(providers = [RunInfo]),
        "shell": attrs.dep(default = "root//:bash-closure", providers = [NixClosureInfo]),
    },
)
