#!/usr/bin/env bash

set -euo pipefail

if ! command -v kind > /dev/null ; then
    printf "kind binary not found in path.\n"
    exit 1
fi

cat > kind-config.yaml <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
EOF

kind create cluster --config kind-config.yaml