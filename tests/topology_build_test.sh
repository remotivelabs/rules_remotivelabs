#!/usr/bin/env bash
# Content check for the remotive_topology_build rule: the fixture instance
# is named `getting-started`, so the output tree must contain a non-empty
# <out>/getting-started/ directory.
set -euo pipefail

: "${TOPOLOGY_OUT:?TOPOLOGY_OUT must point at the topology output directory}"

fail() {
  echo "FAIL: $1" >&2
  echo "--- ${TOPOLOGY_OUT}:" >&2
  ls -laR "${TOPOLOGY_OUT}" >&2 || true
  exit 1
}

[[ -d "${TOPOLOGY_OUT}/getting-started" ]] || fail "getting-started/ missing from output"

# `find -L` follows symlinks — Bazel exposes runfiles entries as symlinks.
file_count=$(find -L "${TOPOLOGY_OUT}/getting-started" -type f | wc -l)
[[ "${file_count}" -gt 0 ]] || fail "getting-started/ is empty"

echo "OK: ${file_count} files under getting-started/"
