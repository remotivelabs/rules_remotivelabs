"""
Manifest of supported `remotive-topology` releases.

Keyed by version. Each entry maps a platform string (e.g. `linux-x86_64`,
`linux-aarch64`, `darwin-arm64`) to the sha256 of the release tarball for
that platform.

The default URL pattern is defined in `remotive_topology_repo.bzl`
(`_BASE_URL`); the manifest only carries hashes.

To add a new version:
  1. Pull the published sha256 sums from the same mirror as `_BASE_URL`:
     `curl -fsSL https://releases.beamylabs.com/experimental/remotive-topology-<X>-{linux-x86_64,linux-aarch64,darwin-arm64}.tar.gz.sha256`
  2. Add an entry below.
  3. Bump `MODULE.bazel` (and any examples / tests pinned to a specific
     version) to the new version.
"""

REMOTIVE_TOPOLOGY_VERSIONS = {
    "0.29.1": {
        "linux-x86_64": "9f37da230a3a3929fc7b143e1f286588b3db1003dd3e1c64dbcf2a53218529bd",
        "linux-aarch64": "2521b3fab9019a9b87ef8350ff0ab9251cfe4d4889151cc1405ee3d89e8ce7d7",
        "darwin-arm64": "5c43ef611cfdac01792c7309a08414a01ba42c9885565f53e06f22c1a096c14b",
    },
}
