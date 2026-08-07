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
    "0.30.0": {
        "linux-x86_64": "fe1cdca53e5608a65572254c9e6784509418acd7fc9ac40c84e53bfed7f0b6d3",
        "linux-aarch64": "c5922dc8dea78b5ecaffbf66f7fb4527b5ec7f21f2ce0a6234d60056f7fbf360",
        "darwin-arm64": "ab2e1c51ca2c2b8c88bc149108aa7e0518598018320b8adf7d897e70967ec2af",
    },
    "0.29.1": {
        "linux-x86_64": "9f37da230a3a3929fc7b143e1f286588b3db1003dd3e1c64dbcf2a53218529bd",
        "linux-aarch64": "2521b3fab9019a9b87ef8350ff0ab9251cfe4d4889151cc1405ee3d89e8ce7d7",
        "darwin-arm64": "5c43ef611cfdac01792c7309a08414a01ba42c9885565f53e06f22c1a096c14b",
    },
}
