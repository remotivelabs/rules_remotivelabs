#!/usr/bin/env bash
# Content check for the `remotive topology show instance|platform` rules:
# both resolve the minimal fixture into a JSON document that must carry the
# platform's two CAN channels.
set -euo pipefail

: "${RESOLVED_OUT:?RESOLVED_OUT must point at the resolved JSON document}"

fail() {
  echo "FAIL: $1" >&2
  echo "--- ${RESOLVED_OUT}:" >&2
  cat "${RESOLVED_OUT}" >&2
  exit 1
}

expect() {
  grep -q "$1" "${RESOLVED_OUT}" || fail "$2"
}

[[ -s "${RESOLVED_OUT}" ]] || fail "resolved document missing or empty"

# `--json` is passed by the rule; a YAML document would start with a key.
[[ "$(head -c 1 "${RESOLVED_OUT}")" == "{" ]] || fail "expected a JSON object"

expect '"DriverCan0"' "DriverCan0 channel missing"
expect '"BodyCan0"' "BodyCan0 channel missing"

echo "OK"
