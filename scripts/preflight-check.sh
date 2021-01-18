#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname $0)/.."

function preflight_check() {
    fail="false"

    printf "Looking for required binaries\n\n"

    printf "kubectl installed\t"
    if ! command -v kubectl > /dev/null ; then
        printf "x\n"
        fail="true"
    else
        printf "✓\t(version: $(kubectl version --short --client)\t\t\tpath: $(command -v kubectl))\n"
    fi

    printf "kustomize installed\t"
    if ! command -v kustomize > /dev/null ; then
        printf "x\n"
        fail="true"
    else
        printf "✓\t(version: $(kustomize version --short)\tpath: $(command -v kustomize))\n"
    fi

    printf "helm installed\t\t"
    if ! command -v helm > /dev/null ; then
        printf "x\n"
        fail="true"
    else
        printf "✓\t(version: $(helm version --short)\t\t\t\tpath: $(command -v helm))\n"
    fi

    if $fail = "true" ; then
        printf "\nSome binaries are missing.\n"
        printf "Check that the required tools are installed in your PATH.\n"
        printf "You can use the 'download-tools.sh' script in the scripts directory to download any missing tools.\n"
    else
        printf "\nAll required binaries found.\n\n"
    fi

    printf "Looking for required services\n\n"

    printf "docker:\t\t\t"
    if ! output=$(docker info 2>&1); then
        printf "x\n\n"
        printf "Docker error output:\n\n"
        printf "$output\n\n"
        fail="true"
    else
        printf "✓\t(version: $(docker version -f '{{.Server.Version}}'))\n"
    fi

    printf "kubernetes:\t\t"
    if ! command -v kubectl > /dev/null; then
        printf "x\t(kubectl binary not found)\n\n"

    elif ! output=$(kubectl version --short 2>&1); then
        printf "x\n\n"
        printf "kubernetes is not running or unreachable. If you have docker installed you can use the create-k3d-cluster.sh script to create a local cluster.\n"
        printf "\nkubectl error output:\n\n"
        printf "$output\n\n"
        fail="true"
    else
        printf "✓\t(version: $(kubectl version --short | tail -n 1 | tr -d " ")\tcontext: $(kubectl config current-context)\tuser: $(kubectl config view --minify -o jsonpath='{.users[0].name}'))\n"
    fi

    if $fail == "true"; then
        exit 1
    fi

    printf "\nAll checks passed.\n"
}

preflight_check
