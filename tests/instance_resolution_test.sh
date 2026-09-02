#!/usr/bin/env bash
set -euo pipefail

: "${INSTANCE_OUT:?INSTANCE_OUT must point at the resolved instance document}"

[[ -s "${INSTANCE_OUT}" ]]
grep -q '"DriverCan0"' "${INSTANCE_OUT}"
grep -q '"BodyCan0"' "${INSTANCE_OUT}"
echo "OK"
