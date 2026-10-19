NixClosureInfo = provider(fields = {
    # Directory artifact laid out as nix/store/<basename>/...
    "tree": provider_field(typing.Any),
    # Role -> relocated store path basename, e.g. "glibc" -> "<hash>-glibc-2.44-25".
    "roots": provider_field(dict[str, str]),
    # Role -> the basename the root has in nixpkgs, before relocation.
    "originals": provider_field(dict[str, str]),
    # Every store path in the closure -> the store paths it refers to.
    "references": provider_field(dict[str, list[str]]),
})

def store_path(closure: NixClosureInfo, role: str, subpath: str = ""):
    """A path inside a root of the closure, as a projection of the one artifact."""
    return store_path_of(closure, closure.roots[role], subpath)

def store_path_of(closure: NixClosureInfo, base: str, subpath: str = ""):
    path = "nix/store/" + base
    return closure.tree.project(path + "/" + subpath if subpath else path)

def requisites(closure: NixClosureInfo, bases: list[str]) -> list[str]:
    """The given store paths and everything they refer to, transitively."""
    seen = {b: True for b in bases}
    todo = list(bases)
    for _ in range(len(closure.references)):
        if not todo:
            break
        found = []
        for base in todo:
            for ref in closure.references[base]:
                if ref not in seen:
                    seen[ref] = True
                    found.append(ref)
        todo = found
    return list(seen)

def _nix_closure_impl(ctx: AnalysisContext) -> list[Provider]:
    for role, base in ctx.attrs.roots.items():
        if base not in ctx.attrs.references:
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
        # Remove when OSS buck2's REAPI client can extend TTLs.
        expires_after_timestamp = 0,
        is_directory = True,
    )
    return [
        DefaultInfo(default_output = tree),
        NixClosureInfo(
            tree = tree,
            roots = ctx.attrs.roots,
            originals = ctx.attrs.originals,
            references = ctx.attrs.references,
        ),
    ]

# A relocated closure (nix/relocate.py), pinned by digest. nix_closures.bzl,
# written by `nix run .#push-closure`, has the attributes for each.
nix_closure = rule(
    impl = _nix_closure_impl,
    attrs = {
        "digest": attrs.string(doc = "REAPI Directory digest of the relocated closure, <sha256>:<size>"),
        "roots": attrs.dict(attrs.string(), attrs.string()),
        "originals": attrs.dict(attrs.string(), attrs.string()),
        "references": attrs.dict(attrs.string(), attrs.list(attrs.string())),
    },
)
