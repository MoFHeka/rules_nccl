"""
Core rules for building projects with NCCL projects.
"""

load("//nccl/private:os_helpers.bzl", _cc_import_versioned_sos = "cc_import_versioned_sos", _if_linux = "if_linux", _if_windows = "if_windows")

if_linux = _if_linux
if_windows = _if_windows

cc_import_versioned_sos = _cc_import_versioned_sos
