"""
A rule for import nccl library
"""

load("//nccl/private:repositories.bzl", _local_nccl = "local_nccl", _rules_nccl_dependencies = "rules_nccl_dependencies")

rules_nccl_dependencies = _rules_nccl_dependencies
local_nccl = _local_nccl
