"""
Analysis tests for the action contract every topology rule shares.

Each `remotive_topology_*` rule registers exactly one `RemotiveTopology*`
action through `_run_topology`. These tests pin what that action's env may
and may not carry: the hermetic values the rule sets unconditionally and
the credentials it must leave to the consumer's `--action_env`. Breaking
either silently would leak host state into the action key or make the
credentials impossible to forward.

The `requires-network` execution requirement is not reachable from the
Starlark `Action` API; check it with
`bazel aquery 'mnemonic("RemotiveTopology.*", //tests:all)' --output=text`.
That it actually grants network is exercised by the CI step that runs the
example consumer under `--spawn_strategy=linux-sandbox
--sandbox_default_allow_network=false`.
"""

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")

# Set unconditionally by the rule. Mirrors `_ACTION_ENV` in
# //remotivelabs/rules:remotive_topology.bzl.
_PINNED_ENV = {
    "PATH": "/bin:/usr/bin:/usr/local/bin",
    "REMOTIVE_CLOUD_ANALYTICS_CONSENT": "true",
    "REMOTIVE_TOPOLOGY_CACHE_DISABLED": "true",
}

# Derived per action: both point into the `<name>_scratch` tree the action
# declares as an output, so nothing outside the action can seed them.
_SCRATCH_DIRS = {
    "REMOTIVE_CONFIG_DIR": "config",
    "REMOTIVE_CACHE_DIR": "cache",
}

# Forwarded from the consumer's invocation env via `--action_env`. Setting
# any of these in the rule would override the consumer's value.
_FORWARDED_ENV = [
    "REMOTIVE_CLOUD_AUTH_TOKEN",
    "REMOTIVE_CLOUD_ORGANIZATION",
    "REMOTIVE_CLOUD_BASE_URL",
    "REMOTIVE_CLOUD_PUBLIC_KEY",
    "https_proxy",
    "HTTPS_PROXY",
    "no_proxy",
    "NO_PROXY",
]

# What a consumer forwards with `--action_env=NAME=VALUE` in the forwarding
# test below; each value must reach the action unchanged.
_FORWARDED_SENTINELS = {
    "REMOTIVE_CLOUD_AUTH_TOKEN": "sentinel-token",
    "REMOTIVE_CLOUD_ORGANIZATION": "sentinel-org",
    "HTTPS_PROXY": "http://sentinel-proxy:3128",
}

def _topology_action(env):
    for action in analysistest.target_actions(env):
        if action.mnemonic.startswith("RemotiveTopology"):
            return action
    analysistest.fail(env, "no RemotiveTopology* action registered")
    return None

def _scratch_output(action):
    for output in action.outputs.to_list():
        if output.is_directory and output.basename.endswith("_scratch"):
            return output
    return None

def _action_contract_test_impl(ctx):
    env = analysistest.begin(ctx)
    action = _topology_action(env)
    if action:
        for name, value in _PINNED_ENV.items():
            asserts.equals(env, value, action.env.get(name), name + " must be pinned")
        scratch = _scratch_output(action)
        asserts.true(env, scratch != None, "the action must declare its scratch tree as an output")
        if scratch:
            for name, subdir in _SCRATCH_DIRS.items():
                asserts.equals(
                    env,
                    scratch.path + "/" + subdir,
                    action.env.get(name),
                    name + " must point into the action's scratch tree",
                )
        for name in _FORWARDED_ENV:
            asserts.false(env, name in action.env, name + " must be left to --action_env")
    return analysistest.end(env)

action_contract_test = analysistest.make(_action_contract_test_impl)

def _forwarding_test_impl(ctx):
    env = analysistest.begin(ctx)
    action = _topology_action(env)
    if action:
        for name, value in _FORWARDED_SENTINELS.items():
            asserts.equals(env, value, action.env.get(name), name + " must reach the action unchanged")

        # A consumer's PATH must not displace the pinned one.
        asserts.equals(env, _PINNED_ENV["PATH"], action.env.get("PATH"), "the pinned PATH must win")
    return analysistest.end(env)

# Analyses the target as a consumer forwarding credentials and a proxy
# would, plus a PATH that must lose to the rule's pinned value. Guards
# `use_default_shell_env = True`: dropping it would leave the contract test
# green while silently cutting every consumer off from forwarding.
forwarding_test = analysistest.make(
    _forwarding_test_impl,
    config_settings = {
        "//command_line_option:action_env": [
            name + "=" + value
            for name, value in _FORWARDED_SENTINELS.items()
        ] + ["PATH=/host/bin"],
    },
)

def action_contract_tests(name, targets):
    """Checks the action contract on one target per topology rule.

    Args:
      name: prefix for the generated test targets and name of the suite.
      targets: labels of `remotive_topology_*` targets, one per rule.
    """
    tests = []
    for target in targets:
        test_name = name + "_" + native.package_relative_label(target).name
        action_contract_test(
            name = test_name,
            target_under_test = target,
        )
        forwarding_test(
            name = test_name + "_forwarding",
            target_under_test = target,
        )
        tests.extend([":" + test_name, ":" + test_name + "_forwarding"])
    native.test_suite(
        name = name,
        tests = tests,
    )
