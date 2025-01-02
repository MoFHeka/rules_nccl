"""Tests for NCCL import functionality."""

load("@local_nccl//:defs.bzl", "if_local_nccl")
load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")

def _test_nccl_import_impl(ctx):
    env = unittest.begin(ctx)
    asserts.true(env, (if_local_nccl("test") == "test"), "if_local_nccl init fail.")
    return unittest.end(env)

nccl_import_test = unittest.make(_test_nccl_import_impl)

def nccl_import_test_suite():
    """Creates the test suite for NCCL import tests."""
    unittest.suite(
        "nccl_import_tests",
        nccl_import_test,
    )
