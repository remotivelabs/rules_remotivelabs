"""Unit tests for `version.bzl`."""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//remotivelabs/private/remotive_topology:version.bzl", "parse_version", "version_at_least")

def _parse_version_test_impl(ctx):
    env = unittest.begin(ctx)
    asserts.equals(env, (0, 30, 1), parse_version("0.30.1"))
    asserts.equals(env, (1, 0), parse_version("1.0"))
    return unittest.end(env)

parse_version_test = unittest.make(_parse_version_test_impl)

def _version_at_least_test_impl(ctx):
    env = unittest.begin(ctx)
    asserts.true(env, version_at_least("0.30.0", "0.30.0"), "equal")
    asserts.true(env, version_at_least("0.32.1", "0.30.0"), "newer minor")
    asserts.true(env, version_at_least("1.0.0", "0.30.0"), "newer major")
    asserts.false(env, version_at_least("0.29.5", "0.30.0"), "older minor")
    asserts.false(env, version_at_least("0.30.0", "0.30.1"), "older patch")

    # Components compare numerically, not lexically: "9" < "30".
    asserts.false(env, version_at_least("0.9.9", "0.30.0"), "numeric compare")
    return unittest.end(env)

version_at_least_test = unittest.make(_version_at_least_test_impl)

def version_test_suite(name):
    """Bundles the version helper tests.

    Args:
      name: name of the test suite target.
    """
    unittest.suite(name, parse_version_test, version_at_least_test)
