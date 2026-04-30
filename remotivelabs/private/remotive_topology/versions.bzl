"""
Manifest of supported `remotive-topology` releases.

Keyed by version. Each entry maps a platform string (e.g. `linux-x86_64`,
`linux-aarch64`) to the sha256 of the release tarball for that platform.

The default URL pattern is defined in `remotive_topology_repo.bzl`
(`_BASE_URL`); the manifest only carries hashes.

To add a new version:
  1. Pull the published sha256 sums from the same mirror as `_BASE_URL`:
     `curl -fsSL https://releases.beamylabs.com/experimental/remotive-topology-<X>-{linux-x86_64,linux-aarch64}.tar.gz.sha256`
  2. Add an entry below.
  3. Bump `MODULE.bazel` (and any examples / tests pinned to a specific
     version) to the new version.
"""

REMOTIVE_TOPOLOGY_VERSIONS = {
    "0.23.0": {
        "linux-x86_64": "46f72a27f25fb0fcf899a00b18016d8ca96c6c4e80bb311e7b2e0895451d71b4",
        "linux-aarch64": "037eb7bccf09a232b806503f11c91c55f786b30f1c650c46cf25906ef5062e83",
    },
}
