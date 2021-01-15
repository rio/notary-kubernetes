#!/usr/bin/env bash

set -euo pipefail

function detect_download_tool() {
    if ! command -v curl > /dev/null ; then
        printf "curl not found.\n"
        exit 1
    fi
}


function make_bin_and_cd() {
    # move to the repo root
    cd "$(dirname $0)/.."

    if ! [ -d bin ]; then
        mkdir bin
    fi

    cd bin
}

if [ "$OSTYPE" = "linux-gnu" ]; then
    NOTARY_URL=https://github.com/theupdateframework/notary/releases/download/v0.6.1/notary-Linux-amd64
    NOTARY_SHASUM=73353b2b4b85604c738a6800465133cb3a828dff0aa26f3c0926dd9a73e19879

    KUSTOMIZE_URL=https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv3.8.9/kustomize_v3.8.9_linux_amd64.tar.gz
    KUSTOMIZE_SHASUM=eb81252cc5dca85660639b224da34c118308435f53f4d74a5094d88dfcb185ac

    K3D_URL=https://github.com/rancher/k3d/releases/download/v3.4.0/k3d-linux-amd64
    K3D_SHASUM=1c961f1161d7b7fb55658ee32081b250a0da6d5f81e40c307a0300e3e130d19f

    KUBECTL_URL=https://storage.googleapis.com/kubernetes-release/release/v1.20.0/bin/linux/amd64/kubectl
    KUBECTL_SHASUM=a5895007f331f08d2e082eb12458764949559f30bcc5beae26c38f3e2724262c

    HELM_URL=https://get.helm.sh/helm-v3.4.2-linux-amd64.tar.gz
    HELM_BINARY_PATH=linux-amd64/helm
    HELM_SHASUM=d14d54d59558caebe234500f541fc2064b08d725ed8aa76f957f91c8d6a0fc46

elif [ "$OSTYPE" = "darwin" ]; then
    NOTARY_URL=https://github.com/theupdateframework/notary/releases/download/v0.6.1/notary-Darwin-amd64
    NOTARY_SHASUM=9593cc0a341e7fe1d01e6834e9964558318a8679c058b6da755b8608dbeac3de

    KUSTOMIZE_URL=https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv3.8.9/kustomize_v3.8.9_darwin_amd64.tar.gz
    KUSTOMIZE_SHASUM=08fc96342720c1c438175888f0555f9bb4cca197829c699057a86607dc383564

    K3D_URL=https://github.com/rancher/k3d/releases/download/v3.4.0/k3d-darwin-amd64
    K3D_SHASUM=54b9b855eddcc3408fbd4f16eaafa6fffd54b17b7224ebe469ce0b2afe9e674c

    KUBECTL_URL=https://storage.googleapis.com/kubernetes-release/release/v1.20.0/bin/darwin/amd64/kubectl
    KUBECTL_SHASUM=82046a4abb056005edec097a42cc3bb55d1edd562d6f6f38c07318603fcd9fca

    HELM_URL=https://get.helm.sh/helm-v3.4.2-darwin-amd64.tar.gz
    HELM_BINARY_PATH=darwin-amd64/helm
    HELM_SHASUM=71eae390246b1c6f4244d04aa7354d3a4d86e0c4e81ed5c967eb0bab47619870
fi

function validate_binary() {
    echo "$1  $2" | sha256sum --status -c -
    chmod +x $2
}

function download_required() {
    printf "## Downloading binaries\n"
    printf "kubectl\t\t"
    curl -sSfLo kubectl $KUBECTL_URL
    printf "✓\n"

    printf "kustomize\t"
    curl -sSfL $KUSTOMIZE_URL | tar xz
    printf "✓\n"

    printf "helm\t\t"
    curl -sSfL $HELM_URL | tar xzOf - ${HELM_BINARY_PATH} > helm
    printf "✓\n"

    printf "k3d\t\t"
    curl -sSfLo k3d $K3D_URL
    printf "✓\n"

    printf "notary\t\t"
    curl -sSfLo notary $NOTARY_URL
    printf "✓\n"

    printf "\n## Validating binaries\n"
    printf "kubectl\t\t"
    validate_binary $KUBECTL_SHASUM kubectl
    printf "✓\n"

    printf "kustomize\t"
    validate_binary $KUSTOMIZE_SHASUM kustomize
    printf "✓\n"

    printf "helm\t\t"
    validate_binary $HELM_SHASUM helm
    printf "✓\n"

    printf "k3d\t\t"
    validate_binary $K3D_SHASUM k3d
    printf "✓\n"

    printf "notary\t\t"
    validate_binary $NOTARY_SHASUM notary
    printf "✓\n"
}

function print_path_message() {
    printf "\nDo not forget to add the $PWD directory to your path so other\n\
scripts can use these binaries. Run the following command in the root of\n\
this repository to enable the bin folder for this terminal.\n\n export PATH=\$PATH:\$PWD/bin\n"
}

detect_download_tool
make_bin_and_cd
download_required
print_path_message