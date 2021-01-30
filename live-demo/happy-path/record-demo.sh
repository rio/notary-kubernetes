#!/usr/bin/env bash

set -euo pipefail

if ! command -v script > /dev/null ; then
    printf "script binary not found in path.\n"
    exit 1
fi

if ! command -v doitlive > /dev/null ; then
    printf "doitlive not found in path.\n"
    exit 1
fi

cd "$(dirname $0)/../.."

script -T live-demo/happy-path/timing live-demo/happy-path/typescript -c "doitlive play -q live-demo/happy-path/session.sh"