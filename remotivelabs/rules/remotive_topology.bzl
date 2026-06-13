"""
Generates topology files from `*.instance.yaml` sources by invoking the
native `remotive-topology` binary inside the Bazel sandbox.

The binary is resolved through the Bazel toolchain that
`rules_remotivelabs` registers globally via the
`@remotivelabs_topology_toolchains` hub repo — consumers only declare a
version with `remotivelabs.topology(...)`. RBE workers pick up the
binary matching their exec platform automatically.
"""

_TOOLCHAIN_TYPE = "@rules_remotivelabs//remotivelabs/toolchains/remotive_topology:toolchain_type"

def _impl(ctx):
    out_dir = ctx.actions.declare_directory(ctx.label.name + "_out")
    binary = ctx.toolchains[_TOOLCHAIN_TYPE].topology_info.binary

    args = ctx.actions.args()
    args.add("build")
    # No workspace exists in the sandbox; the positional output path is
    # required in this mode. Per-action caching still works via REMOTIVE_CACHE_DIR.
    args.add("--no-workspace")
    args.add(out_dir.path)
    for src in ctx.files.srcs:
        args.add("-f", src.path)

    # Hermetic per-action env for the topology binary. The binary's
    # XDG resolver honors `REMOTIVE_<KIND>_DIR > XDG_<KIND>_HOME/remotive
    # > $HOME/<XDG-default>`, so pinning slot 1 keeps every config and
    # cache write inside the Bazel sandbox regardless of consumer env.
    env = {
        # Pre-consent — the interactive consent prompt can't run inside
        # the Bazel sandbox. Transitional; will be dropped once the binary
        # requires REMOTIVE_CLOUD_AUTH_TOKEN for every call.
        "REMOTIVE_CLOUD_ANALYTICS_CONSENT": "true",
        # Hermetic per-action dirs.
        "REMOTIVE_CONFIG_DIR": "/tmp/remotive-config",
        "REMOTIVE_CACHE_DIR": "/tmp/remotive-cache",
    }

    ctx.actions.run(
        executable = binary,
        arguments = [args],
        inputs = depset(ctx.files.srcs + ctx.files.data),
        outputs = [out_dir],
        env = env,
        # ERTS wrappers shell out to `dirname` etc.; need host PATH.
        use_default_shell_env = True,
        mnemonic = "RemotiveTopologyGenerate",
        progress_message = "Generating topology for %{label}",
    )

    return [DefaultInfo(files = depset([out_dir]))]

remotive_topology_generate = rule(
    implementation = _impl,
    attrs = {
        "srcs": attr.label_list(
            allow_files = True,
            mandatory = True,
            doc = "Topology source files (`*.instance.yaml`) to process.",
        ),
        "data": attr.label_list(
            allow_files = True,
            default = [],
            doc = "Additional data files referenced by the topology " +
                  "(included databases, platform files, dockerfiles, etc.).",
        ),
    },
    toolchains = [_TOOLCHAIN_TYPE],
)
