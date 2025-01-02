"""Generate `@local_nccl//`"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")
load("//nccl/private:template_helper.bzl", "template_helper")

def _to_forward_slash(s):
    return s.replace("\\", "/")

def _is_linux(ctx):
    return ctx.os.name.startswith("linux")

def _is_windows(ctx):
    return ctx.os.name.lower().startswith("windows")

def _get_nccl_version(repository_ctx, nccl_include_path):
    nccl_h_path = nccl_include_path + "/nccl.h"
    result = repository_ctx.execute([
        "bash",
        "-c",
        "grep -E '#define NCCL_(MAJOR|MINOR|PATCH)' " + str(nccl_h_path) + " | awk '{print $3}'",
    ])

    if result.return_code != 0:
        fail("Failed to extract NCCL version from " + nccl_h_path + ": " + result.stderr)

    versions = result.stdout.strip().split("\n")

    if len(versions) != 3:
        fail("Expected 3 version numbers (MAJOR, MINOR, PATCH), but got: " + str(versions))

    return versions

def detect_nccl(repository_ctx):
    """Detect nccl Toolkit.

    The path to nccl Toolkit is determined as:
      - the value of `nccl_path` passed to local_nccl as an attribute
      - taken from `NCCL_HOME` environment variable or
      - determined through nccl_lib_paths or
      - defaults to '/usr/lib/x86_64-linux-gnu/nccl'

    Args:
        repository_ctx: repository_ctx

    Returns:
        A struct contains the information of NCCL path.
    """
    NCCL_HOME = repository_ctx.attr.nccl_path
    if NCCL_HOME == "":
        NCCL_HOME = repository_ctx.os.environ.get("NCCL_HOME", None)
    if NCCL_HOME == None:
        NCCL_HOME = repository_ctx.os.environ.get("NCCL_PATH", None)
    if NCCL_HOME == None:
        nccl_lib_paths = ["lib64/", "lib/powerpc64le-linux-gnu/", "lib/x86_64-linux-gnu/", ""]
        for nccl_path in nccl_lib_paths:
            alternative_lib = repository_ctx.path("/usr/" + nccl_path + "nccl/lib/libnccl.so")
            alternative_include = repository_ctx.path("/usr/" + nccl_path + "nccl/include/nccl.h")
            if alternative_lib.exists and alternative_include.exists:
                NCCL_HOME = str(alternative_lib.dirname.dirname)
                break
    if NCCL_HOME == None and _is_linux(repository_ctx):
        NCCL_HOME = "/usr/lib/x86_64-linux-gnu/nccl"

    if NCCL_HOME != None and not repository_ctx.path(NCCL_HOME).exists:
        NCCL_HOME = None

    nccl_include_path = None
    nccl_lib_path = None
    if NCCL_HOME != None:
        nccl_include_path = NCCL_HOME + "/include"
        nccl_lib_path = NCCL_HOME + "/lib"

    nccl_version_major = -1
    nccl_version_minor = -1
    nccl_version_patch = -1

    if NCCL_HOME != None:
        nccl_version_major, nccl_version_minor, nccl_version_patch = _get_nccl_version(repository_ctx, nccl_include_path)

    return struct(
        path = NCCL_HOME,
        # this should have been extracted from nccl.h
        version_major = nccl_version_major,
        version_minor = nccl_version_minor,
        nccl_version_major = nccl_version_major,
        nccl_version_minor = nccl_version_minor,
        nccl_version_patch = nccl_version_patch,
        nccl_include_path = nccl_include_path,
        nccl_lib_path = nccl_lib_path,
    )

def config_local_nccl(repository_ctx, nccl):
    """Generate `@local_nccl//BUILD` and `@local_nccl//defs.bzl` and `@local_nccl//toolchain/BUILD`

    Args:
        repository_ctx: repository_ctx
        nccl: The struct returned from detect_nccl
    """

    # True: locally installed nccl toolkit
    # False: hermatic nccl toolkit (components)
    # None: nccl toolkit is not presented
    is_local_nccl = None
    if nccl.path != None:
        repository_ctx.symlink(nccl.path, "nccl")
        is_local_nccl = True

    # Generate @local_nccl//BUILD
    if is_local_nccl == None:
        # TODO(MoFHeka): Build a github NCCL repo here using rules_cuda
        repository_ctx.symlink(Label("//nccl:templates/BUILD.local_nccl_disabled"), "BUILD")
    elif is_local_nccl:
        libpath = "lib64" if _is_linux(repository_ctx) else "lib"
        template_helper.generate_build(repository_ctx, libpath)
    else:
        fail("local nccl dependencies is not implemented")

    # Generate @local_nccl//defs.bzl
    template_helper.generate_defs_bzl(repository_ctx, is_local_nccl)

def _local_nccl_impl(repository_ctx):
    nccl = detect_nccl(repository_ctx)
    config_local_nccl(repository_ctx, nccl)

local_nccl = repository_rule(
    implementation = _local_nccl_impl,
    attrs = {"nccl_path": attr.string(mandatory = False)},
    configure = True,
    local = True,
    environ = ["NCCL_HOME", "NCCL_PATH"],
    # remotable = True,
)

def rules_nccl_dependencies(nccl_path = None):
    """Populate the dependencies for rules_nccl. This will setup workspace dependencies (other bazel rules) and local toolchains.

    Args:
        nccl_path: Optionally specify the path to NCCL. If not specified, it will be detected automatically.
    """
    maybe(
        name = "bazel_skylib",
        repo_rule = http_archive,
        sha256 = "bc283cdfcd526a52c3201279cda4bc298652efa898b10b4db0837dc51652756f",
        urls = [
            "https://mirror.bazel.build/github.com/bazelbuild/bazel-skylib/releases/download/1.7.1/bazel-skylib-1.7.1.tar.gz",
            "https://github.com/bazelbuild/bazel-skylib/releases/download/1.7.1/bazel-skylib-1.7.1.tar.gz",
        ],
    )

    maybe(
        name = "platforms",
        repo_rule = http_archive,
        sha256 = "218efe8ee736d26a3572663b374a253c012b716d8af0c07e842e82f238a0a7ee",
        urls = [
            "https://mirror.bazel.build/github.com/bazelbuild/platforms/releases/download/0.0.10/platforms-0.0.10.tar.gz",
            "https://github.com/bazelbuild/platforms/releases/download/0.0.10/platforms-0.0.10.tar.gz",
        ],
    )

    local_nccl(name = "local_nccl", nccl_path = nccl_path)
