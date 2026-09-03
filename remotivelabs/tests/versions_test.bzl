"""
Consistency checks for the `remotive-topology` release manifest.

Every version must list exactly the platforms the toolchain hub knows how
to register, and every hash must look like a sha256 digest. Catches a
mis-pasted checksum or a forgotten platform at `bazel test` time, before a
consumer's repository fetch fails.
"""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//remotivelabs/private/remotive_topology:topology_toolchains_hub.bzl", "SUPPORTED_PLATFORMS")
load("//remotivelabs/private/remotive_topology:version.bzl", "parse_version")
load("//remotivelabs/private/remotive_topology:versions.bzl", "REMOTIVE_TOPOLOGY_VERSIONS")

_HEX_DIGITS = "0123456789abcdef"

def _is_sha256(value):
    if len(value) != 64:
        return False
    for char in value.elems():
        if char not in _HEX_DIGITS:
            return False
    return True

def _manifest_test_impl(ctx):
    env = unittest.begin(ctx)
    asserts.true(env, len(REMOTIVE_TOPOLOGY_VERSIONS) > 0, "manifest is empty")

    for version, platforms in REMOTIVE_TOPOLOGY_VERSIONS.items():
        asserts.equals(
            env,
            3,
            len(parse_version(version)),
            "{}: version keys are MAJOR.MINOR.PATCH".format(version),
        )
        asserts.equals(
            env,
            sorted(SUPPORTED_PLATFORMS),
            sorted(platforms.keys()),
            "{}: must list exactly the supported platforms".format(version),
        )
        for platform, sha256 in platforms.items():
            asserts.true(
                env,
                _is_sha256(sha256),
                "{} {}: sha256 must be 64 lowercase hex chars".format(version, platform),
            )

    return unittest.end(env)

manifest_test = unittest.make(_manifest_test_impl)

def versions_test_suite(name):
    """Bundles the manifest consistency tests.

    Args:
      name: name of the test suite target.
    """
    unittest.suite(name, manifest_test)
