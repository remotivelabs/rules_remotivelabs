"""
Module extension for rules_remotivelabs.

For each `remotivelabs.topology(version = "X.Y.Z")` requested by the dep
graph, the extension creates one repository per (version, platform)
listed in `versions.bzl`. It also always materialises a stable-name
`@remotivelabs_topology_toolchains` hub repo that aggregates every
(version, platform) into `toolchain(...)` registrations. The rules' own
`MODULE.bazel` registers `@remotivelabs_topology_toolchains//:all`
globally, so consumers don't need to repeat the registration.
"""

load("//remotivelabs/private/remotive_topology:remotive_topology_repo.bzl", "remotive_topology_repo")
load("//remotivelabs/private/remotive_topology:topology_toolchains_hub.bzl", "topology_toolchains_hub")
load("//remotivelabs/private/remotive_topology:versions.bzl", "REMOTIVE_TOPOLOGY_VERSIONS")

_HUB_REPO_NAME = "remotivelabs_topology_toolchains"

def _per_platform_repo_name(version, platform):
    """e.g. ("0.23.0", "linux-x86_64") -> "remotive_topology_0_23_0_linux_x86_64" """
    return "remotive_topology_{}_{}".format(
        version.replace(".", "_"),
        platform.replace("-", "_"),
    )

def _remotivelabs_impl(mctx):
    # Deduplicate — multiple modules may request the same version.
    versions = {}
    for mod in mctx.modules:
        for tag in mod.tags.topology:
            versions[tag.version] = tag

    repos = []
    platforms = []
    toolchain_names = []
    for version in sorted(versions.keys()):
        entry = REMOTIVE_TOPOLOGY_VERSIONS.get(version)
        if not entry:
            fail(
                ("remotive-topology version {!r} is not in the manifest. " +
                 "Known versions: {}. Add a new entry to " +
                 "remotivelabs/private/remotive_topology/versions.bzl to register it.")
                    .format(version, sorted(REMOTIVE_TOPOLOGY_VERSIONS.keys())),
            )
        for platform in sorted(entry.keys()):
            repo_name = _per_platform_repo_name(version, platform)
            remotive_topology_repo(
                name = repo_name,
                version = version,
                platform = platform,
            )
            repos.append(repo_name)
            platforms.append(platform)
            toolchain_names.append(repo_name)

    # Always create the hub. With no versions requested it just emits an
    # empty BUILD.bazel; `register_toolchains(":all")` then matches zero
    # targets, harmlessly.
    topology_toolchains_hub(
        name = _HUB_REPO_NAME,
        repos = repos,
        platforms = platforms,
        toolchain_names = toolchain_names,
    )

remotivelabs = module_extension(
    implementation = _remotivelabs_impl,
    tag_classes = {
        "topology": tag_class(attrs = {
            "version": attr.string(
                mandatory = True,
                doc = "remotive-topology release version, e.g. \"0.23.0\". " +
                      "Must be present in REMOTIVE_TOPOLOGY_VERSIONS.",
            ),
        }),
    },
)
