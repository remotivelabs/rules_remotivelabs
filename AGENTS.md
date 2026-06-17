# Agent Roles

## Bazel Rules Developer
**When:** Implementing or modifying the module extension, the
`remotive_topology_repo` repository rule, the `remotive_topology_build`
action rule, or the `remotive_topology_toolchain` plumbing.
**Responsibilities:**
- Distribution is a single tar archive per `(version, arch)`, downloaded via
  `ctx.download_and_extract` in the repository rule. URL pattern:
  `https://releases.beamylabs.com/experimental/remotive-topology-{version}-linux-{arch}.tar.gz`.
- The tar extracts to `remotive_topology/bin/remotive-topology` (wrapper
  shell script) + bundled OTP runtime under `remotive_topology/lib/` and
  `remotive_topology/erts-*/`. Expose `remotive_topology/bin/remotive-topology`
  as the Bazel target.
- The extension creates **one repo per (version, platform)** in the
  manifest — names like `remotive_topology_0_23_0_linux_x86_64`. Each
  per-platform repo emits `:topology` (`sh_binary`) and `:toolchain_impl`
  (`remotive_topology_toolchain`).
- The extension also always materialises a stable-name hub repo,
  `@remotivelabs_topology_toolchains`, whose generated `BUILD.bazel`
  declares one `toolchain(...)` per (version, platform), each carrying
  the matching `exec_compatible_with` constraints. The rules' own
  `MODULE.bazel` registers `@remotivelabs_topology_toolchains//:all`,
  which propagates globally — consumers don't write `register_toolchains`.
- Per-platform repos fetch lazily — Bazel only downloads the binary for
  the platform actually selected by toolchain resolution. RBE workers on
  a different arch from the host trigger the appropriate fetch on demand.
- Keep `extensions.bzl` and the repository rule simple — naming convention
  is centralised in `_get_topology_repo_name`. Do not duplicate it.
- Use **template files** (`.tpl`) for generated `BUILD.bazel` content — no
  inline strings in repository rules.
- `examples/remotive_topology` is a self-contained child workspace —
  a real consumer with its own `MODULE.bazel` using `local_path_override`.
  Keep it up to date when changing the rule's public surface; exercise
  it with `cd examples/remotive_topology && bazel test //...`.
- The action rule's env-var contract is documented in the comment block
  of [`remotivelabs/rules/remotive_topology.bzl`](remotivelabs/rules/remotive_topology.bzl) — the canonical
  source of truth for "set unconditionally" vs "forwarded" semantics.
  Keep it in sync with any change to `env = {...}` in that rule.
- Two categories: **set unconditionally** (consent bypass, config dir,
  cache flag, HOME) vs **forwarded from consumer's invocation env** via
  `--action_env=NAME`. The forwarded set is just the cloud creds:
  `REMOTIVE_CLOUD_AUTH_TOKEN` (for per-user metric attribution) and the
  optional endpoint overrides `REMOTIVE_CLOUD_BASE_URL`,
  `REMOTIVE_CLOUD_ORGANIZATION`, `REMOTIVE_CLOUD_PUBLIC_KEY`. Forwarded
  vars must NOT appear in the rule's `env` dict — that would override
  the user-supplied value. `use_default_shell_env = True` is what makes
  `--action_env` flow through to the action.
- `TOPOLOGY` is *not* read by the topology binary; it's read by the
  broker (which the topology binary doesn't start as part of its OTP
  application set). The binary emits `TOPOLOGY=true` as a literal into
  generated `docker-compose.yml`, so downstream broker containers pick
  it up. No need to forward it through Bazel.

## Module Maintainer
**When:** Adding a new `remotive-topology` version, cutting a module
release, or updating module-level dependencies.
**Responsibilities:**
- Adding a version:
  1. Confirm the release exists at the URL pattern above for every
     platform you intend to support.
  2. Fetch the sha256 sums from the matching `.sha256` siblings.
  3. Add an entry to `remotivelabs/private/remotive_topology/versions.bzl`
     keyed by version, mapping each platform string to its sha256.
  4. Bump the `remotivelabs.topology(version = "X.Y.Z")` call in the
     root `MODULE.bazel` (only the version string changes — no per-arch
     plumbing). Bump `examples/remotive_topology/MODULE.bazel` the same
     way.
  5. Update the `tests/BUILD.bazel` `topology_extension_test` target
     names and the root `MODULE.bazel` `use_repo` entries that reference
     the per-platform repos for testing.
  6. Refresh both `MODULE.bazel.lock` files: `bazel mod deps` from the
     root, then again from `examples/remotive_topology/`. Run
     `bazel test //tests:all` and `cd examples/remotive_topology && bazel test //...`.
- Bumping the module: update `version` in the root `MODULE.bazel`; keep
  `examples/remotive_topology/MODULE.bazel.lock` in sync.

# Reference Documentation
- Topology workspace: https://docs.remotivelabs.com/docs/remotive-topology/workspace
- Topology platform files: https://docs.remotivelabs.com/docs/remotive-topology/usage/platform
- Topology instance files: https://docs.remotivelabs.com/docs/remotive-topology/usage/instance
- Topology running: https://docs.remotivelabs.com/docs/remotive-topology/usage/running
- Topology JSON API: https://docs.remotivelabs.com/apis/json/topology

# Principles
- **bzlmod first:** All features and examples use bzlmod (`MODULE.bazel`).
  WORKSPACE-based usage is not supported.

# Execution Rules
- **Test layering (fast first):**
  1. `bazel test //tests:all` — load + unit tests on the rules themselves.
  2. `cd examples/remotive_topology && bazel test //...` — consumer-shape
     check against the example child workspace.
- Starlark code should be readable without deep Bazel expertise — document
  non-obvious decisions inline.
- Do not modify `examples/` without also running its tests
  (`cd examples/remotive_topology && bazel test //...`).
- Avoid duplication across `.bzl` files — prefer a single source of truth.
- Keep code clean and elegant; avoid over-engineering.
