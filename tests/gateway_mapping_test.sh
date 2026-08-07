#!/usr/bin/env bash
# Content check for the remotive_topology_gateway_mapping e2e: the dummy
# ARXML fixture declares four forwarding routes covering every channel-type
# combination (CAN->CAN, CAN->ETH, ETH->LIN, LIN->CAN); all four must
# survive extraction and emission.
set -euo pipefail

: "${MAPPING_OUT:?MAPPING_OUT must point at the mapping document}"

fail() {
  echo "FAIL: $1" >&2
  echo "--- ${MAPPING_OUT}:" >&2
  cat "${MAPPING_OUT}" >&2
  exit 1
}

expect() {
  grep -q "$1" "${MAPPING_OUT}" || fail "$2"
}

[[ -s "${MAPPING_OUT}" ]] || fail "mapping document missing or empty"

expect "^schema: https://releases.remotivelabs.com/schemas/remotive-topology-mapping/" \
  "schema key missing"

# CAN -> CAN
expect "SensorFrame01: ActuatorFrame01" "CAN->CAN route missing"
# CAN -> ethernet.pdu (gateway-side socket first, peer socket second)
expect "SensorFrame01: PtBackboneStatusPdu01" "CAN->ETH route missing"
expect "source_socket: GatewayBackboneSocket" "ethernet source socket missing"
expect "target_socket: TelematicsBackboneSocket" "ethernet target socket missing"
# ethernet.pdu -> LIN
expect "PtBackboneCommandPdu01: ClimateFrame01" "ETH->LIN route missing"
# LIN -> CAN
expect "ClimateStateFrame01: ClimateStateCanFrame01" "LIN->CAN route missing"

echo "OK"
