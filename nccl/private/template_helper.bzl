"""
Functions for generate BUILD files from templates
"""

load("//nccl/private:templates/registry.bzl", "REGISTRY")

def _to_forward_slash(s):
    return s.replace("\\", "/")

def _is_linux(ctx):
    return ctx.os.name.startswith("linux")

def _is_windows(ctx):
    return ctx.os.name.lower().startswith("windows")

def _generate_build(repository_ctx, libpath):
    # stitch template fragment
    fragments = [
        Label("//nccl/private:templates/BUILD.local_nccl_shared"),
        Label("//nccl/private:templates/BUILD.local_nccl_headers"),
    ]
    fragments.extend([Label("//nccl/private:templates/BUILD.{}".format(c)) for c in REGISTRY if len(REGISTRY[c]) > 0])

    template_content = []
    for frag in fragments:
        template_content.append("# Generated from fragment " + str(frag))
        template_content.append(repository_ctx.read(frag))

    template_content = "\n".join(template_content)

    template_path = repository_ctx.path("BUILD.tpl")
    repository_ctx.file(template_path, content = template_content, executable = False)

    substitutions = {
        "%{component_name}": "nccl",
        "%{libpath}": libpath,
    }
    repository_ctx.template("BUILD", template_path, substitutions = substitutions, executable = False)

def _generate_defs_bzl(repository_ctx, is_local_nccl):
    tpl_label = Label("//nccl/private:templates/defs.bzl.tpl")
    substitutions = {
        "%{is_local_nccl}": str(is_local_nccl),
    }
    repository_ctx.template("defs.bzl", tpl_label, substitutions = substitutions, executable = False)

template_helper = struct(
    generate_build = _generate_build,
    generate_defs_bzl = _generate_defs_bzl,
)
