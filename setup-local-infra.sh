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

# Parse options
while getopts ":n:c:a:k:p:lf:h" opt; do
    case ${opt} in
        h )
            print_local_options
            exit 0
            ;;
        n )
            ARGO_NAME=${OPTARG}
            ;;
        c )
            KIND_CONTEXT=${OPTARG}
            ;;
        a )
            ARGO_CLUSTER=${OPTARG}
            ;;
        k )
            KIND_CLUSTER=${OPTARG}
            ;;
        p )
            ARGO_PORT=${OPTARG}
            ;;
        f )
            LOG_FILE=${OPTARG}
            ;;
        l )
            ENABLE_LOGS=1
            ;;
        \? )
            echo "Invalid option: -$OPTARG" 1>&2
            echo "\n"
            print_local_options
            exit 1
            ;;
    esac
done

# Check for any prerequisites
check_dependencies

# Create the kind cluster
if [ ! "$(check_cluster_status $KIND_CLUSTER)" ]; then
    if [ ! -z "$KIND_IMAGE" ]; then
        info "attempting to create a kind cluster"
        kind create cluster --name $KIND_CLUSTER \
            --image "$KIND_IMAGE" || \
            err "failed to create $KIND_CLUSTER"
    fi
fi

# Create the ArgoCD cluster
if [ "$(check_cluster_status $KIND_CLUSTER)" ]; then
    info "attempting to create an ArgoCD cluster"
    create_argocd_cluster || err "failed to create the cluster"

    info "waiting for services to be ready"
    map_argocd_server && info "localhost for ArgoCD configured successfully"

    info "waiting on port configuration"
    test_argocd_login && info "tests finished; the ArgoCD interface is ready"
fi

# Ensure the appropriate context
use_kind_context
