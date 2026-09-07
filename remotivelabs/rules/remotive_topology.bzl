"""
Rules that invoke the native `remotive-topology` binary inside the
Bazel sandbox: `remotive_topology_build` builds topology files from
`*.instance.yaml` sources; `remotive_topology_show_instance` and
`remotive_topology_show_platform` resolve an instance or a platform into
JSON; `remotive_topology_gateway_mapping` extracts one gateway ECU's
mapping document from a platform.

The binary is resolved through the Bazel toolchain that
`rules_remotivelabs` registers globally via the
`@remotivelabs_topology_toolchains` hub repo — consumers only declare a
version with `remotivelabs.topology(...)`. RBE workers pick up the
binary matching their exec platform automatically.
"""

load("//remotivelabs/private/remotive_topology:version.bzl", "version_at_least")

_TOOLCHAIN_TYPE = "@rules_remotivelabs//remotivelabs/toolchains/remotive_topology:toolchain_type"

RemotiveTopologyBuildInfo = provider(
    doc = "Build metadata for a generated RemotiveTopology.",
    fields = {
        "name": "The topology target name.",
        "output_dir": "The generated topology tree artifact.",
        "sources": "The declared source and data closure.",
    },
)

# `gateway-mapping --no-workspace` and `--format` first shipped in this release.
_GATEWAY_MAPPING_FLAGS_MIN_VERSION = "0.30.0"

# Action env contract for the topology binary. This block is the canonical
# description (see AGENTS.md); keep it in sync with the dict below and with
# the README's "Analytics and network" section.
#
# Set unconditionally — the dict below: PATH, the analytics consent bypass,
# the on-disk cache switch and the config/cache dirs. The binary's XDG
# resolver honors `REMOTIVE_<KIND>_DIR > XDG_<KIND>_HOME/remotive >
# $HOME/<XDG-default>`, so pinning slot 1 keeps every write out of the
# consumer's home regardless of their env.
#
# Forwarded from the consumer's invocation env with `--action_env=NAME`.
# These must never appear in the dict below: a value here would override
# the consumer's.
#   REMOTIVE_CLOUD_AUTH_TOKEN + REMOTIVE_CLOUD_ORGANIZATION — credentials
#     for per-org analytics attribution. They go together: the binary
#     rejects a token without an organization, and with the config dir
#     pinned to an empty location no config.json can supply one.
#   REMOTIVE_CLOUD_BASE_URL, REMOTIVE_CLOUD_PUBLIC_KEY — optional endpoint
#     overrides.
#   https_proxy/HTTPS_PROXY, no_proxy/NO_PROXY — read by the binary's HTTP
#     client; needed wherever Remotive Cloud sits behind a proxy.
_ACTION_ENV = {
    # The release is an OTP tree whose `sh` wrappers call `dirname`, `sed`
    # and friends, so an action needs *a* PATH. Pin the value Bazel's
    # --incompatible_strict_action_env uses (the default since Bazel 9).
    # Consumers on older Bazel, or with that flag off, would otherwise
    # inherit the host PATH into the action key. The fixed env wins over
    # the default shell env merged in below.
    "PATH": "/bin:/usr/bin:/usr/local/bin",
    # Pre-consent — the interactive consent prompt can't run inside the
    # Bazel sandbox. Transitional; will be dropped once the binary
    # requires REMOTIVE_CLOUD_AUTH_TOKEN for every call.
    "REMOTIVE_CLOUD_ANALYTICS_CONSENT": "true",
    # The binary caches parsed signal databases on disk, validated by
    # mtime, and turns that cache on whenever it detects a workspace
    # marker (`remotive.yaml` or `.remotive/`) above its working directory.
    # A consumer keeping one at the repo root has it in the execroot, so
    # `show` (which has no --no-workspace) would start writing to the dir
    # below. Nothing survives an action anyway; switch the cache off.
    "REMOTIVE_TOPOLOGY_CACHE_DISABLED": "true",
    # Hermetic per-action dirs, the backstop for every other writer
    # (consent record, completion cache). Only private under a sandbox
    # with a hermetic /tmp; the local strategy and macOS share the host's.
    "REMOTIVE_CONFIG_DIR": "/tmp/remotive-config",
    "REMOTIVE_CACHE_DIR": "/tmp/remotive-cache",
}

def _run_topology(ctx, args, inputs, outputs, mnemonic, progress_message):
    """Runs the toolchain's `remotive-topology` binary as one hermetic action.

    Every rule in this file goes through here so the action env contract
    (`_ACTION_ENV` and its comment block) is applied in exactly one place.
    """
    ctx.actions.run(
        executable = ctx.toolchains[_TOOLCHAIN_TYPE].topology_info.binary,
        arguments = [args],
        inputs = depset(inputs),
        outputs = outputs,
        env = _ACTION_ENV,
        # Only here so that `--action_env=NAME` forwarding works for the
        # cloud credentials; PATH itself is pinned in _ACTION_ENV.
        use_default_shell_env = True,
        # The binary authorizes every invocation against Remotive Cloud
        # and fails when it can't reach it. Say so, so sandboxes and
        # remote executors that block network by default grant it here.
        # Stopgap until the generator no longer needs network to generate.
        execution_requirements = {"requires-network": ""},
        mnemonic = mnemonic,
        progress_message = progress_message,
    )

def _build_impl(ctx):
    out_dir = ctx.actions.declare_directory(ctx.label.name + "_out")
    inputs = ctx.files.srcs + ctx.files.data

    args = ctx.actions.args()
    args.add("build")

    # No workspace exists in the sandbox; the positional output path is
    # required in this mode.
    args.add("--no-workspace")
    args.add(out_dir.path)
    for src in ctx.files.srcs:
        args.add("-f", src.path)

    _run_topology(
        ctx,
        args,
        inputs = inputs,
        outputs = [out_dir],
        mnemonic = "RemotiveTopologyBuild",
        progress_message = "Building topology for %{label}",
    )

    return [
        DefaultInfo(files = depset([out_dir])),
        RemotiveTopologyBuildInfo(
            name = ctx.label.name,
            output_dir = out_dir,
            sources = depset(inputs),
        ),
    ]

remotive_topology_build = rule(
    implementation = _build_impl,
    provides = [RemotiveTopologyBuildInfo],
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

def _run_show(ctx, subcommand, flags, progress_message):
    """Runs `remotive-topology show <subcommand>` and returns the JSON output file.

    `show` has no `--no-workspace` flag; without a workspace marker the
    binary uses its working directory (the action's execroot) as the path
    boundary, which both the source and the output path satisfy.
    """
    output = ctx.actions.declare_file(ctx.label.name + ".json")

    args = ctx.actions.args()
    args.add_all(["show", subcommand, ctx.file.src.path, "--json"])
    args.add_all(flags)
    args.add("--out-path", output.path)

    _run_topology(
        ctx,
        args,
        inputs = [ctx.file.src] + ctx.files.data,
        outputs = [output],
        mnemonic = "RemotiveTopologyShow" + subcommand.capitalize(),
        progress_message = progress_message,
    )

    return [DefaultInfo(files = depset([output]))]

def _show_instance_impl(ctx):
    return _run_show(
        ctx,
        "instance",
        ["--check"],
        "Resolving topology instance for %{label}",
    )

remotive_topology_show_instance = rule(
    implementation = _show_instance_impl,
    doc = "Resolves and validates an instance into a JSON document: `<name>.json`.",
    attrs = {
        "src": attr.label(
            allow_single_file = True,
            mandatory = True,
            doc = "The root `*.instance.yaml` file to resolve.",
        ),
        "data": attr.label_list(
            allow_files = True,
            default = [],
            doc = "Additional included instance/platform/database files.",
        ),
    },
    toolchains = [_TOOLCHAIN_TYPE],
)

def _show_platform_impl(ctx):
    return _run_show(
        ctx,
        "platform",
        [],
        "Resolving topology platform for %{label}",
    )

remotive_topology_show_platform = rule(
    implementation = _show_platform_impl,
    doc = "Resolves a platform into a JSON document: `<name>.json`. The " +
          "source may be a `*.platform.yaml`, a `*.instance.yaml` (its " +
          "platform is shown) or a single signal database.",
    attrs = {
        "src": attr.label(
            allow_single_file = True,
            mandatory = True,
            doc = "The `*.platform.yaml`, `*.instance.yaml` or database " +
                  "file (`.arxml`, `.dbc`, `.ldf`, `.xml`, `.signaldb.yaml`) " +
                  "to resolve.",
        ),
        "data": attr.label_list(
            allow_files = True,
            default = [],
            doc = "Files the source references (signal databases, " +
                  "included platform/instance files, ...).",
        ),
    },
    toolchains = [_TOOLCHAIN_TYPE],
)

def _gateway_mapping_impl(ctx):
    out = ctx.actions.declare_file(ctx.label.name + ".mapping.yaml")
    version = ctx.toolchains[_TOOLCHAIN_TYPE].topology_info.version

    args = ctx.actions.args()
    args.add("gateway-mapping")
    args.add("--gateway-ecu", ctx.attr.gateway_ecu)
    args.add("--platform", ctx.file.platform.path)

    # Workaround for remotive-topology < 0.30.0, which has neither
    # `--no-workspace` nor `--format`. Those releases only emit the legacy
    # structure and, without a workspace marker, already accept paths
    # anywhere under the working directory (the action's execroot). Drop
    # this branch, and pass both flags unconditionally, once 0.29.x is
    # removed from versions.bzl.
    if version_at_least(version, _GATEWAY_MAPPING_FLAGS_MIN_VERSION):
        # No workspace exists in the sandbox; the positional output path is
        # required in this mode.
        args.add("--no-workspace")
        args.add("--format", ctx.attr.format)
    elif ctx.attr.format != "legacy":
        fail(("format '{}' needs remotive-topology >= {}; the resolved " +
              "toolchain provides {}.").format(
            ctx.attr.format,
            _GATEWAY_MAPPING_FLAGS_MIN_VERSION,
            version,
        ))
    args.add(out.path)

    _run_topology(
        ctx,
        args,
        inputs = [ctx.file.platform] + ctx.files.data,
        outputs = [out],
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
                  "`remotive-topology-mapping` document (needs " +
                  "remotive-topology >= 0.30.0).",
        ),
    },
    toolchains = [_TOOLCHAIN_TYPE],
)
