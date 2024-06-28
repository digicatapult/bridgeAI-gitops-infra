#!/bin/bash

# Copyright Digital Catapult 2024. All rights reserved.

# Name
# Bridge AI: Local GitOps infrastructure

# Description:
# This installer creates local ArgoCD clusters around kind.

# Usage:
# ./setup-local-infra.sh
# Once configured, try localhost:8080 in a browser or use the argocd CLI.

# Initialise
. common/init.sh

# Check for any prerequisites
check_dependencies

# Create the kind cluster
if [ ! "$(check_cluster_status kind-kind)" ]; then
    if [ ! -z "$KIND_IMAGE" ]; then
        info "attempting to create a kind cluster"
        kind create cluster --image "$KIND_IMAGE" || \
            err "failed to create using $KIND_IMAGE"
    fi
fi

# Create the ArgoCD cluster
if [ "$(check_cluster_status kind-kind)" ]; then
    info "attempting to create an ArgoCD cluster"
    create_argocd_cluster || err "failed to create the cluster"

    info "waiting for pods to be ready" && sleep 60
    map_argocd_server && info "localhost for ArgoCD configured successfully"

    info "waiting on port configuration" && sleep 2
    test_argocd_login && info "tests finished; the ArgoCD interface is ready"
fi
