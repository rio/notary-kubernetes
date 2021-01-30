#!/usr/bin/env bash

set -euo pipefail

if ! command -v scriptreplay > /dev/null ; then
    printf "scriptreplay binary not found in path.\n"
    exit 1
fi

cd "$(dirname $0)/../.."

scriptreplay -T live-demo/happy-path/timing live-demo/happy-path/typescript