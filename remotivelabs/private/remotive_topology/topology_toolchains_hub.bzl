"""
Hub repo aggregating per-(version, platform) repos into a single BUILD.bazel
of `toolchain(...)` declarations. Always materialised by the module
extension (even if no versions are requested — `register_toolchains` then
matches zero targets, harmlessly).

The rules' own `MODULE.bazel` registers `@remotivelabs_topology_toolchains//:all`
globally so consumers don't need their own `register_toolchains` line.
"""

# Maps the manifest's platform string to the @platforms//{os,cpu}:*
# constraints baked into each emitted `toolchain(...)` target.
_PLATFORM_CONSTRAINTS = {
    "linux-x86_64": ("@platforms//os:linux", "@platforms//cpu:x86_64"),
    "linux-aarch64": ("@platforms//os:linux", "@platforms//cpu:aarch64"),
}

def _topology_toolchains_hub_impl(ctx):
    block_template = ctx.read(ctx.attr._block_template)
    blocks = []
    for i in range(len(ctx.attr.repos)):
        repo = ctx.attr.repos[i]
        platform = ctx.attr.platforms[i]
        name = ctx.attr.toolchain_names[i]

        constraints = _PLATFORM_CONSTRAINTS.get(platform)
        if not constraints:
            fail("Unknown platform {!r} in topology_toolchains_hub; expected one of {}.".format(
                platform,
                sorted(_PLATFORM_CONSTRAINTS.keys()),
            ))
        os_c, cpu_c = constraints

        blocks.append(block_template.format(
            name = name,
            repo = repo,
            os_constraint = os_c,
            cpu_constraint = cpu_c,
        ))

    build_template = ctx.read(ctx.attr._build_template)
    ctx.file("BUILD.bazel", build_template.format(
        toolchains = "\n".join(blocks),
    ))

topology_toolchains_hub = repository_rule(
    implementation = _topology_toolchains_hub_impl,
    attrs = {
        "repos": attr.string_list(
            mandatory = True,
            doc = "Per-(version, platform) repo names. Parallel to `platforms` and `toolchain_names`.",
        ),
        "platforms": attr.string_list(
            mandatory = True,
            doc = "Platform strings (e.g. 'linux-x86_64'). Parallel to `repos`.",
        ),
        "toolchain_names": attr.string_list(
            mandatory = True,
            doc = "Names for the emitted `toolchain(...)` targets. Parallel to `repos`.",
        ),
        "_build_template": attr.label(
            default = Label("@rules_remotivelabs//remotivelabs/private/remotive_topology:topology_toolchains_hub_BUILD.bazel.tpl"),
            allow_single_file = True,
        ),
        "_block_template": attr.label(
            default = Label("@rules_remotivelabs//remotivelabs/private/remotive_topology:topology_toolchain_BLOCK.bazel.tpl"),
            allow_single_file = True,
        ),
    },
    doc = "Generates a BUILD.bazel of `toolchain(...)` registrations for every (version, platform) pair.",
)
