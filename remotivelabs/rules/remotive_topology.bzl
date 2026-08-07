"""
Rules that invoke the native `remotive-topology` binary inside the
Bazel sandbox: `remotive_topology_build` builds topology files from
`*.instance.yaml` sources; `remotive_topology_gateway_mapping` extracts
one gateway ECU's mapping document from a platform.

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
        mnemonic = "RemotiveTopologyBuild",
        progress_message = "Building topology for %{label}",
    )

    return [DefaultInfo(files = depset([out_dir]))]

remotive_topology_build = rule(
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

def _gateway_mapping_impl(ctx):
    out = ctx.actions.declare_file(ctx.label.name + ".mapping.yaml")
    binary = ctx.toolchains[_TOOLCHAIN_TYPE].topology_info.binary

    args = ctx.actions.args()
    args.add("gateway-mapping")

    # No workspace exists in the sandbox; the positional output path is
    # required in this mode.
    args.add("--no-workspace")
    args.add("--gateway-ecu", ctx.attr.gateway_ecu)
    args.add("--platform", ctx.file.platform.path)
    args.add("--format", ctx.attr.format)
    args.add(out.path)

    # Same hermetic per-action env as remotive_topology_build; see the
    # comments there.
    env = {
        "REMOTIVE_CLOUD_ANALYTICS_CONSENT": "true",
        "REMOTIVE_CONFIG_DIR": "/tmp/remotive-config",
        "REMOTIVE_CACHE_DIR": "/tmp/remotive-cache",
    }

    ctx.actions.run(
        executable = binary,
        arguments = [args],
        inputs = depset([ctx.file.platform] + ctx.files.data),
        outputs = [out],
        env = env,
        # ERTS wrappers shell out to `dirname` etc.; need host PATH.
        use_default_shell_env = True,
        mnemonic = "RemotiveTopologyGatewayMapping",
        progress_message = "Extracting gateway mapping for %{label}",
    )

    return [DefaultInfo(files = depset([out]))]

remotive_topology_gateway_mapping = rule(
    implementation = _gateway_mapping_impl,
    doc = "Extracts the gateway mapping for one gateway ECU from a " +
          "topology platform. The gateway ECU's database must be an " +
          "ARXML ECU extract (declared in the platform, typically via " +
          "an `includes:` entry). The output is a single mapping " +
          "document: `<name>.mapping.yaml`.",
    attrs = {
        "gateway_ecu": attr.string(
            mandatory = True,
            doc = "Name of the gateway ECU to extract mappings for.",
        ),
        "platform": attr.label(
            allow_single_file = True,
            mandatory = True,
            doc = "The `*.platform.yaml` describing channels and ECUs.",
        ),
        "data": attr.label_list(
            allow_files = True,
            default = [],
            doc = "Files the platform references (signal databases, " +
                  "included platform files, ...).",
        ),
        "format": attr.string(
            default = "legacy",
            values = ["legacy", "remotive-topology-mapping"],
            doc = "Mapping structure to emit: the legacy gateway-mapping " +
                  "structure (default) or the versioned " +
                  "`remotive-topology-mapping` document.",
        ),
    },
    toolchains = [_TOOLCHAIN_TYPE],
)
