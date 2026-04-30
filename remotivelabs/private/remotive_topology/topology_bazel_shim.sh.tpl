#!/bin/bash
# Bazel-aware shim materialized by remotive_topology_repo.bzl.
#
# The release tarball's bin/remotive-topology wrapper resolves its release
# root via `$(dirname "$0")/..`, which lands outside the release when Bazel
# launches the binary from `bazel-out/`. This shim locates the release in
# the runfiles tree first, then delegates to the original wrapper with the
# same arguments — so `dirname` resolution works inside the sandbox.
#
# Falls back to a sibling layout for direct (non-Bazel) invocation.
set -eo pipefail

_find_release_root() {
    local rf="${BASH_SOURCE[0]}.runfiles"
    if [[ -d "$rf" ]]; then
        local d
        for d in "$rf"/*/remotive_topology; do
            [[ -d "$d" ]] && { echo "$d"; return 0; }
        done
    fi
    if [[ -n "${RUNFILES_DIR:-}" ]]; then
        local d
        for d in "${RUNFILES_DIR}"/*/remotive_topology; do
            [[ -d "$d" ]] && { echo "$d"; return 0; }
        done
    fi
    # Direct (non-Bazel) invocation: shim sits next to the release dir.
    (cd "$(dirname "${BASH_SOURCE[0]}")/remotive_topology" && pwd)
}

RELEASE_ROOT=$(_find_release_root)
exec "${RELEASE_ROOT}/bin/remotive-topology" "$@"
