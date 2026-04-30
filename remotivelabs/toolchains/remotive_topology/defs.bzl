"""
Toolchain provider and rule for the `remotive-topology` native binary.

Used together with the `toolchain_type` declared in this package's
`BUILD.bazel`. Each per-(version, platform) repository created by the
`remotivelabs.topology(...)` extension emits one
`remotive_topology_toolchain` target (`:toolchain_impl`) wrapping its
bundled binary. The stable-name `@remotivelabs_topology_toolchains` hub
repo aggregates these into `toolchain(...)` registrations with
`exec_compatible_with` constraints; the rules' own `MODULE.bazel`
registers `@remotivelabs_topology_toolchains//:all` so the toolchains
are available globally without consumer-side `register_toolchains`.

`remotive_topology_generate` resolves the binary through
`ctx.toolchains[...]`.
"""

RemotiveTopologyToolchainInfo = provider(
    doc = "Information about the remotive-topology binary that the action rule needs.",
    fields = {
        "binary": "FilesToRunProvider for the topology executable.",
    },
)

def _remotive_topology_toolchain_impl(ctx):
    return [
        platform_common.ToolchainInfo(
            topology_info = RemotiveTopologyToolchainInfo(
                binary = ctx.attr.binary[DefaultInfo].files_to_run,
            ),
        ),
    ]

remotive_topology_toolchain = rule(
    implementation = _remotive_topology_toolchain_impl,
    attrs = {
        "binary": attr.label(
            mandatory = True,
            executable = True,
            cfg = "exec",
            doc = "Label of the topology binary (the sh_binary materialised by the repo rule).",
        ),
    },
    doc = "Wraps a `remotive-topology` binary as a Bazel toolchain.",
)
