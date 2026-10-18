NixClosureInfo = provider(fields = {
    # Directory artifact laid out as nix/store/<basename>/...
    "tree": provider_field(typing.Any),
    # Role name -> store path basename, e.g. "glibc" -> "h4wf...-glibc-2.44-25".
    "roots": provider_field(dict[str, str]),
    "paths": provider_field(list[str]),
})

def store_path(closure: NixClosureInfo, role: str, subpath: str = ""):
    """A path inside the closure tree, as a projection of the one artifact."""
    path = "nix/store/" + closure.roots[role]
    return closure.tree.project(path + "/" + subpath if subpath else path)

def _nix_closure_impl(ctx: AnalysisContext) -> list[Provider]:
    for role, base in ctx.attrs.roots.items():
        if base not in ctx.attrs.closure:
            fail("root {} ({}) is not in the closure".format(role, base))

    # The tree is already in the CAS, uploaded by `nix run .#push-closure`.
    # Declaring it by digest downloads nothing: workers get it as an input.
    # It stays one artifact: buck2 rewrites relative symlinks when it copies
    # a directory, which would break links between and within store paths.
    tree = ctx.actions.cas_artifact(
        "closure",
        ctx.attrs.digest,
        "buck2-default",
        # No minimum lifetime: OSS buck2 cannot extend CAS TTLs, and asking for
        # more than `cas_ttl_secs` makes it try. push-closure re-uploads.
        expires_after_timestamp = 0,
        is_directory = True,
    )
    return [
        DefaultInfo(default_output = tree),
        NixClosureInfo(tree = tree, roots = ctx.attrs.roots, paths = ctx.attrs.closure),
    ]

nix_closure = rule(
    impl = _nix_closure_impl,
    attrs = {
        "digest": attrs.string(doc = "REAPI Directory digest of the relocated closure, <sha256>:<size>"),
        "roots": attrs.dict(attrs.string(), attrs.string()),
        "closure": attrs.list(attrs.string(), doc = "Every store path the roots need"),
    },
)
