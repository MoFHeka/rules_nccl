# nccl rules for [Bazel](https://bazel.build)

This repository contains [Starlark](https://github.com/bazelbuild/starlark) implementation of nccl rules in Bazel.

These rules provide some macros and rules that make it easier to build nccl with Bazel.

## Getting Started

### Traditional WORKSPACE approach

Add the following to your `WORKSPACE` file and replace the placeholders with actual values.

```starlark
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
http_archive(
    name = "rules_nccl",
    sha256 = "{sha256_to_replace}",
    strip_prefix = "rules_nccl-{git_commit_hash}",
    urls = ["https://.../{git_commit_hash}.tar.gz"],
)
load("@rules_nccl//nccl:repositories.bzl", "rules_nccl_dependencies")
rules_nccl_dependencies()
```

### Bzlmod

Add the following to your `MODULE.bazel` file and replace the placeholders with actual values.

```starlark
bazel_dep(name = "rules_nccl", version = "0.0.1")

# pick a specific version (this is optional an can be skipped)
archive_override(
    module_name = "rules_nccl",
    integrity = "{SRI value}",  # see https://developer.mozilla.org/en-US/docs/Web/Security/Subresource_Integrity
    urls = "https://.../{git_commit_hash}.tar.gz",
    strip_prefix = "rules_nccl-{git_commit_hash}",
)

nccl = use_extension("@rules_nccl//nccl:extensions.bzl", "toolchain")
nccl.local_toolchain(
    name = "local_nccl",
    toolkit_path = "",
)
use_repo(nccl, "local_nccl")
```

### Available dependencies

- `nccl_runtime`: Can be used to compile and link to NCCL shared library.
- `nccl_runtime_static`: Can be used to compile and link to NCCL static library.
- `@rules_nccl//nccl:runtime`: Default is same as `nccl_runtime`.

### Tests
```bash
bazel test //nccl/tests:all
```
