"""Entry point for extensions used by bzlmod."""

load("//nccl:repositories.bzl", "local_nccl")

nccl_tag = tag_class(attrs = {
    "name": attr.string(doc = "Name for the dependencie repository", default = "local_nccl"),
    "nccl_path": attr.string(doc = "Path to the nccl SDK, if empty the environment variable NCCL_HOME or NCCL_PATH will be used to deduce this path."),
})

def _find_modules(module_ctx):
    root = None
    our_module = None
    for mod in module_ctx.modules:
        if mod.is_root:
            root = mod
        if mod.name == "rules_nccl":
            our_module = mod
    if root == None:
        root = our_module
    if our_module == None:
        fail("Unable to find rules_nccl module")

    return root, our_module

def _init(module_ctx):
    # Dependencie configuration is only allowed in the root module, or in rules_nccl.
    root, rules_nccl = _find_modules(module_ctx)
    dependencies = root.tags.nccl_dependencie or rules_nccl.tags.nccl_dependencie

    registrations = {}
    for dep in dependencies:
        if dep.name in registrations.keys():
            if dep.nccl_path == registrations[dep.name]:
                # No problem to register a matching dependencie twice
                continue
            fail("Multiple conflicting dependencies declared for name {} ({} and {}".format(dep.name, dep.nccl_path, registrations[dep.name]))
        else:
            registrations[dep.name] = dep.nccl_path
    for name, nccl_path in registrations.items():
        local_nccl(name = name, nccl_path = nccl_path)

nccl_dependencie = module_extension(
    implementation = _init,
    tag_classes = {"nccl_dependencie": nccl_tag},
)
