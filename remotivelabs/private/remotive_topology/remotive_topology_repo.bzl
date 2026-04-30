"""
Repository rule that downloads one platform's `remotive-topology` native
tarball and exposes the binary plus a toolchain wrapper.

Created per (version, platform) pair by the module extension. The
`@remotivelabs_topology_toolchains` hub repo (also created by the
extension) aggregates these into `toolchain(...)` registrations with
matching `exec_compatible_with` constraints, so callers only need to
declare the version once.

Archive URL pattern (public Remotive Labs releases mirror):
  https://releases.beamylabs.com/experimental/remotive-topology-{version}-{platform}.tar.gz

Archive layout after extraction:
  remotive_topology/bin/remotive-topology   # outer wrapper (sets LD_LIBRARY_PATH, execs OTP)
  remotive_topology/erts-*/bin/             # wrapped ERTS binaries (sh -> musl <name>.bin)
  remotive_topology/lib/                    # OTP libs + bundled ld-musl-*.so.1 + libgcc_s.so.1
"""

load(":versions.bzl", "REMOTIVE_TOPOLOGY_VERSIONS")

_BASE_URL = "https://releases.beamylabs.com/experimental/remotive-topology-{version}-{platform}.tar.gz"

def _remotive_topology_repo_impl(ctx):
    version = ctx.attr.version
    platform = ctx.attr.platform

    entry = REMOTIVE_TOPOLOGY_VERSIONS.get(version)
    if not entry:
        fail(
            ("remotive-topology version {!r} is not in the manifest. " +
             "Known versions: {}. Add a new entry to versions.bzl to " +
             "register it.").format(
                version,
                sorted(REMOTIVE_TOPOLOGY_VERSIONS.keys()),
            ),
        )
    sha256 = entry.get(platform)
    if not sha256:
        fail(
            ("remotive-topology {!r} has no entry for platform {!r}. " +
             "Available: {}.").format(
                version,
                platform,
                sorted(entry.keys()),
            ),
        )

    url = _BASE_URL.format(version = version, platform = platform)

    ctx.report_progress("Downloading remotive-topology {} for {}".format(version, platform))
    ctx.download_and_extract(
        url = [url],
        sha256 = sha256,
    )

    # Bazel-aware shim that locates the release root in the runfiles tree
    # and execs the in-tarball wrapper. See topology_bazel_shim.sh.tpl for
    # the full script and the runfiles-resolution logic.
    ctx.template(
        "topology_bazel_shim.sh",
        ctx.attr._shim_template,
        executable = True,
    )

    template = ctx.read(ctx.attr._build_template)
    ctx.file("BUILD.bazel", template.format(
        version = version,
        platform = platform,
    ))

    ctx.report_progress("Done")

remotive_topology_repo = repository_rule(
    implementation = _remotive_topology_repo_impl,
    attrs = {
        "version": attr.string(
            mandatory = True,
            doc = "remotive-topology version, e.g. '0.23.0'. " +
                  "Must be present in REMOTIVE_TOPOLOGY_VERSIONS in versions.bzl.",
        ),
        "platform": attr.string(
            mandatory = True,
            doc = "Platform string like 'linux-x86_64' or 'linux-aarch64'. " +
                  "Must be present in the version's entry in versions.bzl.",
        ),
        "_build_template": attr.label(
            default = Label("@rules_remotivelabs//remotivelabs/private/remotive_topology:remotive_topology_BUILD.bazel.tpl"),
            allow_single_file = True,
        ),
        "_shim_template": attr.label(
            default = Label("@rules_remotivelabs//remotivelabs/private/remotive_topology:topology_bazel_shim.sh.tpl"),
            allow_single_file = True,
        ),
    },
    doc = """Downloads one platform's remotive-topology native release tarball.

Created per (version, platform) by the module extension. Targets:

  :topology         — sh_binary, the topology binary wrapped for Bazel
  :toolchain_impl   — `remotive_topology_toolchain`, consumed by the hub

Toolchain registration with platform constraints lives in the
`@remotivelabs_topology_toolchains` hub.
""",
)
