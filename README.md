# rules_remotivelabs

Bazel rules for the [RemotiveLabs](https://remotivelabs.com)
`remotive-topology` generator. Downloads the published native binary
and exposes a `remotive_topology_generate` rule that runs it inside
the Bazel sandbox.

## Usage

`MODULE.bazel`:

```starlark
bazel_dep(name = "rules_remotivelabs", version = "0.1.0")

remotivelabs = use_extension("@rules_remotivelabs//remotivelabs:extensions.bzl", "remotivelabs")
remotivelabs.topology(version = "0.23.0")
```

`BUILD.bazel`:

```starlark
load("@rules_remotivelabs//remotivelabs/rules:remotive_topology.bzl", "remotive_topology_generate")

remotive_topology_generate(
    name = "my_topology",
    srcs = ["topology/instances/main.instance.yaml"],
    data = glob(["topology/**"]),
)
```

`rules_remotivelabs` registers per-platform toolchains globally on the consumer's behalf, so there is no `register_toolchains` line and `BUILD.bazel` callsites don't reference the binary by label. Bumping versions is a one-line change in `MODULE.bazel`. RBE workers automatically resolve the toolchain matching their exec platform.

Supported versions: [`versions.bzl`](remotivelabs/private/remotive_topology/versions.bzl).

## Analytics

Every `remotive_topology_generate` action submits analytics to Remotive
Cloud, attributed to the org behind a **service-account token**.
Forward your token from the shell to Bazel actions:

```
# .bazelrc
build --action_env=REMOTIVE_CLOUD_AUTH_TOKEN
```

```bash
export REMOTIVE_CLOUD_AUTH_TOKEN=$(remotive cloud auth print-access-token)
```

Optional endpoint overrides forward the same way:
`REMOTIVE_CLOUD_BASE_URL`, `REMOTIVE_CLOUD_ORGANIZATION`,
`REMOTIVE_CLOUD_PUBLIC_KEY`.

## Tests

```bash
bazel test //tests:all                                  # rules_remotivelabs unit tests
cd examples/remotive_topology && bazel test //...       # consumer workspace (sample)
```
