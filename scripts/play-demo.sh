#!/usr/bin/env bash

set -euo pipefail

if ! command -v scriptreplay > /dev/null ; then
    printf "scriptreplay binary not found in path.\n"
    exit 1
fi

cd "$(dirname $0)/.."

# this was recorded using the script command and doitlive
# script -T timing typescript -c "doitlive play -q session.sh"

scriptreplay -T live-demo/timing live-demo/typescript