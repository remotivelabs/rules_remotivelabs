"""
Analysis tests for the remotive-topology version gate in
`remotive_topology_gateway_mapping`.

Binaries before 0.30.0 know neither `gateway-mapping --no-workspace` nor
`--format`. The rule must omit both for such a toolchain, reject a
non-legacy `format` at analysis time, and pass both flags to newer
binaries. The tests swap in fake toolchains (declared with
`fake_topology_toolchain`) through `--extra_toolchains`, so no binary is
downloaded or run.
"""

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")
load("@rules_shell//shell:sh_binary.bzl", "sh_binary")
load("//remotivelabs/toolchains/remotive_topology:defs.bzl", "remotive_topology_toolchain")

_TOOLCHAIN_TYPE = "//remotivelabs/toolchains/remotive_topology:toolchain_type"
_MNEMONIC = "RemotiveTopologyGatewayMapping"

# Labels of the fake toolchains declared by `fake_topology_toolchains` in
# this package's BUILD.bazel.
_OLD_TOOLCHAIN = "//remotivelabs/tests:fake_topology_0_29_5"
_NEW_TOOLCHAIN = "//remotivelabs/tests:fake_topology_0_30_0"

def fake_topology_toolchains(name, versions):
    """Declares one never-executed toolchain per version, matching any platform.

    Args:
      name: name of the shared stand-in `sh_binary`.
      versions: release versions to declare a toolchain for; each becomes
        `fake_topology_<version with dots as underscores>`.
    """
    sh_binary(
        name = name,
        srcs = ["fake_topology.sh"],
    )
    for version in versions:
        target = "fake_topology_" + version.replace(".", "_")
        remotive_topology_toolchain(
            name = target + "_impl",
            binary = ":" + name,
            version = version,
        )
        native.toolchain(
            name = target,
            toolchain = ":" + target + "_impl",
            toolchain_type = _TOOLCHAIN_TYPE,
        )

def _gateway_mapping_argv(env):
    for action in analysistest.target_actions(env):
        if action.mnemonic == _MNEMONIC:
            return action.argv
    analysistest.fail(env, "no {} action registered".format(_MNEMONIC))
    return []

def _old_binary_omits_flags_test_impl(ctx):
    env = analysistest.begin(ctx)
    argv = _gateway_mapping_argv(env)
    asserts.true(env, "gateway-mapping" in argv, "subcommand missing")
    asserts.false(env, "--no-workspace" in argv, "--no-workspace passed to a pre-0.30.0 binary")
    asserts.false(env, "--format" in argv, "--format passed to a pre-0.30.0 binary")
    return analysistest.end(env)

old_binary_omits_flags_test = analysistest.make(
    _old_binary_omits_flags_test_impl,
    config_settings = {"//command_line_option:extra_toolchains": [_OLD_TOOLCHAIN]},
)

def _old_binary_rejects_versioned_format_test_impl(ctx):
    env = analysistest.begin(ctx)
    asserts.expect_failure(env, "needs remotive-topology >= 0.30.0")
    asserts.expect_failure(env, "toolchain provides 0.29.5")
    return analysistest.end(env)

old_binary_rejects_versioned_format_test = analysistest.make(
    _old_binary_rejects_versioned_format_test_impl,
    expect_failure = True,
    config_settings = {"//command_line_option:extra_toolchains": [_OLD_TOOLCHAIN]},
)

def _new_binary_passes_flags_test_impl(ctx):
    env = analysistest.begin(ctx)
    argv = _gateway_mapping_argv(env)
    asserts.true(env, "--no-workspace" in argv, "--no-workspace missing")
    asserts.true(env, "--format" in argv, "--format missing")
    asserts.true(env, "remotive-topology-mapping" in argv, "format value missing")
    return analysistest.end(env)

new_binary_passes_flags_test = analysistest.make(
    _new_binary_passes_flags_test_impl,
    config_settings = {"//command_line_option:extra_toolchains": [_NEW_TOOLCHAIN]},
)

def gateway_mapping_analysis_tests(name, legacy_target, versioned_target):
    """Instantiates the version-gate analysis tests.

    Args:
      name: prefix for the generated test targets.
      legacy_target: a `remotive_topology_gateway_mapping` with the default
        (`legacy`) format.
      versioned_target: a `remotive_topology_gateway_mapping` with
        `format = "remotive-topology-mapping"`.
    """
    old_binary_omits_flags_test(
        name = name + "_old_binary_omits_flags",
        target_under_test = legacy_target,
    )
    old_binary_rejects_versioned_format_test(
        name = name + "_old_binary_rejects_versioned_format",
        target_under_test = versioned_target,
    )
    new_binary_passes_flags_test(
        name = name + "_new_binary_passes_flags",
        target_under_test = versioned_target,
    )
    native.test_suite(
        name = name,
        tests = [
            ":" + name + "_old_binary_omits_flags",
            ":" + name + "_old_binary_rejects_versioned_format",
            ":" + name + "_new_binary_passes_flags",
        ],
    )
