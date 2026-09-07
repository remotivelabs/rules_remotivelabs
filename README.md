# rules_remotivelabs

Bazel rules for the [RemotiveLabs](https://remotivelabs.com)
`remotive-topology` generator. Downloads the published native binary
and exposes rules that run it inside the Bazel sandbox:

| Rule | `remotive topology ...` | Output |
|---|---|---|
| `remotive_topology_build` | `build` | directory tree `<name>_out/` |
| `remotive_topology_show_instance` | `show instance --check` | `<name>.json` |
| `remotive_topology_show_platform` | `show platform` | `<name>.json` |
| `remotive_topology_gateway_mapping` | `gateway-mapping` | `<name>.mapping.yaml` |

Attribute docs are rendered by Stardoc:
`bazel build //docs:remotive_topology_md && cat bazel-bin/docs/remotive_topology_build.md`.

## Usage

`MODULE.bazel`:

```starlark
bazel_dep(name = "rules_remotivelabs", version = "0.3.1")

remotivelabs = use_extension("@rules_remotivelabs//remotivelabs:extensions.bzl", "remotivelabs")
remotivelabs.topology(version = "0.32.1")
```

`BUILD.bazel`:

```starlark
load(
    "@rules_remotivelabs//remotivelabs/rules:remotive_topology.bzl",
    "remotive_topology_build",
    "remotive_topology_gateway_mapping",
    "remotive_topology_show_instance",
    "remotive_topology_show_platform",
)

remotive_topology_build(
    name = "my_topology",
    srcs = ["topology/instances/main.instance.yaml"],
    data = glob(["topology/**"]),
)

remotive_topology_show_instance(
    name = "my_resolved_instance",
    src = "topology/instances/main.instance.yaml",
    data = glob(["topology/**"]),
)

remotive_topology_show_platform(
    name = "my_resolved_platform",
    src = "topology/platform/topology.platform.yaml",
    data = glob(["topology/platform/**"]),
)

remotive_topology_gateway_mapping(
    name = "my_gateway_mapping",
    gateway_ecu = "GatewayEcu",
    platform = "topology/platform/topology.platform.yaml",
    data = glob(["topology/platform/**"]),
    format = "remotive-topology-mapping",  # needs remotive-topology >= 0.30.0
)
```

`rules_remotivelabs` registers per-platform toolchains globally on the consumer's behalf, so there is no `register_toolchains` line and `BUILD.bazel` callsites don't reference the binary by label. Bumping versions is a one-line change in `MODULE.bazel`. RBE workers automatically resolve the toolchain matching their exec platform.

Supported versions: [`versions.bzl`](remotivelabs/private/remotive_topology/versions.bzl).

## Analytics and network

Every rule action authorizes itself against Remotive Cloud before it
generates anything, so the actions need network egress to
`cloud.remotivelabs.com`. They carry the `requires-network` execution
requirement for sandboxes and remote executors that block network by
default.

Analytics are attributed to the org behind a **service-account token**.
Forward the token *and* its organization from the shell to Bazel actions;
the binary rejects one without the other:

```
# .bazelrc
build --action_env=REMOTIVE_CLOUD_AUTH_TOKEN
build --action_env=REMOTIVE_CLOUD_ORGANIZATION
```

```bash
export REMOTIVE_CLOUD_AUTH_TOKEN=$(remotive cloud auth print-access-token)
export REMOTIVE_CLOUD_ORGANIZATION=<organization>
```

Optional endpoint overrides forward the same way: `REMOTIVE_CLOUD_BASE_URL`,
`REMOTIVE_CLOUD_PUBLIC_KEY`. Behind a proxy, also forward
`https_proxy`/`HTTPS_PROXY` and `no_proxy`/`NO_PROXY`.

Everything else the binary needs is pinned by the rules — `PATH`, a
disabled on-disk cache, config and cache dirs inside the sandbox — so the
action key never depends on the host. Bazel 9 runs actions with a strict
env by default; on older Bazel add `--incompatible_strict_action_env` so
the rest of your build gets the same treatment.

## Tests

```bash
bazel test //tests:all                                  # rules_remotivelabs unit tests
cd examples/remotive_topology && bazel test //...       # consumer workspace (sample)
```
