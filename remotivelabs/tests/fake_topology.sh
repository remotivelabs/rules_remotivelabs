#!/usr/bin/env bash
# Stand-in binary for the fake toolchains used by analysis tests. Analysis
# tests never execute actions, so this must never run.
echo "fake remotive-topology: not meant to be executed" >&2
exit 1
