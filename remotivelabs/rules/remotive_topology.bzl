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
    args.add("generate")
    args.add(out_dir.path)
    for src in ctx.files.srcs:
        args.add("-f", src.path)

    # Env vars set unconditionally for hermetic sandbox operation.
    # FIX-UPSTREAM tags mark workarounds we should drop once the binary
    # is fixed; the unmarked vars are legitimate Bazel-side config.
    env = {
        # Pre-consent on the user's behalf — the binary's interactive
        # consent prompt can't run inside the Bazel sandbox, and a hard
        # failure on every token-less build would be worse UX than this
        # implicit opt-in. The README discloses the implicit consent.
        #
        # TRANSITIONAL: anonymous analytics is being removed. Once the
        # binary requires a service-account `REMOTIVE_CLOUD_AUTH_TOKEN`
        # for every call, drop this var and let absent tokens fail with
        # a clear error instead of pre-consenting.
        "REMOTIVE_CLOUD_ANALYTICS_CONSENT": "true",
        # Hermetic per-action config dir. FIX-UPSTREAM: when the binary
        # adopts XDG (reads XDG_CONFIG_HOME for `$XDG_CONFIG_HOME/remotive`),
        # this app-specific var becomes redundant and we can drop it.
        "REMOTIVE_CONFIG_DIR": "/tmp/remotive-config",
        # FIX-UPSTREAM: the binary's codec cache writes to
        # `<REMOTIVE_TOPOLOGY_WORKSPACE>/.remotive/cache/...`, which would
        # leak undeclared writes from Bazel's hermetic sandbox. Disabled
        # for now; once the binary honours `XDG_CACHE_HOME` (or any
        # per-action override), redirect to scratch and re-enable so
        # multi-ECU topologies parse shared databases once per action.
        "REMOTIVE_TOPOLOGY_CACHE_DISABLED": "true",
        # FIX-UPSTREAM: drop once the binary stops calling `Path.home()`
        # directly and routes config / cache lookups through XDG vars
        # (`XDG_CONFIG_HOME`, `XDG_CACHE_HOME`, with `$HOME`-relative
        # defaults baked into the XDG spec).
        "HOME": "/tmp",
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
