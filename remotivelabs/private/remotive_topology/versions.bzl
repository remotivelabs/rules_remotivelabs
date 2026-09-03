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

When removing the 0.29.x entries, also drop the `--format` workaround in
`remotivelabs/rules/remotive_topology.bzl` (`remotive_topology_gateway_mapping`);
those releases predate `gateway-mapping --no-workspace` and `--format`.
"""

REMOTIVE_TOPOLOGY_VERSIONS = {
    "0.32.1": {
        "linux-x86_64": "3c3c0086719881df0fe06e642ee0eacc31a5fda562daa7ea24184aef5fdfb695",
        "linux-aarch64": "bc72a5d43e1ac1be3cad8ef0a280f0660729feb35152fb0640fca4bdc3bf8f12",
        "darwin-arm64": "945524739df08649047891d7b3ab94f5fa8e9e6462455075e655323d3528c630",
    },
    "0.32.0": {
        "linux-x86_64": "9a50246609d8b99b8a34fdf61337ca7f9ebc5860148c91ab55bbeb66e7a6760a",
        "linux-aarch64": "6c43bdfab4fd2c093374b03e801cc08b9841b3ce1a344e4f9d2f44a3ad755051",
        "darwin-arm64": "18aebfc4038a77471bc954e5fa3f1b45ead705e9a388db299d5c2221e00714a8",
    },
    "0.31.2": {
        "linux-x86_64": "d962c2dba7897ab81e8d6c1d4d1c830438fd4cc96e2e96382301533d3581dbd8",
        "linux-aarch64": "3dd9ab4633abd4c604c39d6c8ec0f2ddee5cfc5b85f0a848f7269aa3438f145a",
        "darwin-arm64": "7b2c8c294fdaab06e3f0ffafa57f63213cc5f68df68cfe6a25c118ff04a52a3d",
    },
    "0.31.1": {
        "linux-x86_64": "0bd7fee345db1295ab76e8046ae89ee599b042ad3e3171a0bb3e6a731a013d4c",
        "linux-aarch64": "0a06f134abded1335e6c685362f1ca22360867553a1cf74a83a3b13bb5b982e4",
        "darwin-arm64": "325b63550cb4d371413202b647a1a9ba6d166c408d08163ced98dc3fa3af6754",
    },
    "0.31.0": {
        "linux-x86_64": "aa14427f8d0dd777a59b19fa8865499c2ceee9d1f781162a46b6bf3cdb2ac55a",
        "linux-aarch64": "7ccfdbb9e3c2715a21d18bf13e3c0d0cb991925b2bcbcbe3efa92db152f02b8f",
        "darwin-arm64": "8d633d5851a8b6216d6120b36f891c18763f589b78d1956ff100973f0d424d40",
    },
    "0.30.0": {
        "linux-x86_64": "fe1cdca53e5608a65572254c9e6784509418acd7fc9ac40c84e53bfed7f0b6d3",
        "linux-aarch64": "c5922dc8dea78b5ecaffbf66f7fb4527b5ec7f21f2ce0a6234d60056f7fbf360",
        "darwin-arm64": "ab2e1c51ca2c2b8c88bc149108aa7e0518598018320b8adf7d897e70967ec2af",
    },
    "0.29.5": {
        "linux-x86_64": "3433fb7227a764afa1399bba0c74c75ce2929210210c8faba3d625fe5a48c635",
        "linux-aarch64": "af1d0aa63443484b75cb98923d5f15feb7ebd6fc41c637832c4c778a934c3dad",
        "darwin-arm64": "29b65baefdb4bcbc3a5ef13f9257868444f42c2acf0b498f4efc1c87d2e91c5f",
    },
    "0.29.4": {
        "linux-x86_64": "e2c5d4886bf84ab635e74b5b44765049d4ff85965751260f4be2211f1836b225",
        "linux-aarch64": "256b28551f664a0033a6a982d12cab6d87bde2d4bf5d82598ea6b34363d00a03",
        "darwin-arm64": "7e2233be2ebe7d46949eaa36ac1ee710f2fa1c4cbf6cbd5766edc0123e5d70e7",
    },
    "0.29.3": {
        "linux-x86_64": "94c46102df494f4022a7e579535904cbfc8548fd4fec0f9c322b577f6d268fc9",
        "linux-aarch64": "bb460d819a10bf6450846f36167851343d86603a20568f9f99b4f96b501c26ca",
        "darwin-arm64": "d1cdb06b54f9a4f89a89c9a5d23c6addee0c8071c0c84f68a76db1a1430a1554",
    },
    "0.29.1": {
        "linux-x86_64": "9f37da230a3a3929fc7b143e1f286588b3db1003dd3e1c64dbcf2a53218529bd",
        "linux-aarch64": "2521b3fab9019a9b87ef8350ff0ab9251cfe4d4889151cc1405ee3d89e8ce7d7",
        "darwin-arm64": "5c43ef611cfdac01792c7309a08414a01ba42c9885565f53e06f22c1a096c14b",
    },
}
