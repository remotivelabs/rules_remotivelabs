#!/bin/bash
set -euo pipefail

echo "Validating topology generation output..."

if [ -z "${TOPOLOGY_OUT:-}" ]; then
    echo "✗ TOPOLOGY_OUT not set"
    exit 1
fi

if [ ! -d "${TOPOLOGY_OUT}" ]; then
    echo "✗ Output dir ${TOPOLOGY_OUT} does not exist"
    exit 1
fi

# remotive_topology_generate writes the resolved topology under
# <out>/<name>/. The fixture instance is named `getting-started`.
if [ ! -d "${TOPOLOGY_OUT}/getting-started" ]; then
    echo "✗ Expected ${TOPOLOGY_OUT}/getting-started to exist"
    ls -la "${TOPOLOGY_OUT}"
    exit 1
fi

# `find -L` follows symlinks — Bazel exposes runfiles entries as symlinks.
file_count=$(find -L "${TOPOLOGY_OUT}/getting-started" -type f | wc -l)
if [ "${file_count}" -eq 0 ]; then
    echo "✗ No files generated in ${TOPOLOGY_OUT}/getting-started"
    exit 1
fi

echo "✓ Generated ${file_count} files under ${TOPOLOGY_OUT}/getting-started"
exit 0
