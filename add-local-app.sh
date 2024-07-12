#!/bin/bash

# Copyright Digital Catapult 2024. All rights reserved.

# Name
# Bridge AI: Local GitOps application management

# Description:
# This script creates and synchronises a given application via ArgoCD.

# Usage:
# ./add-local-app.sh -a <app_name> -r <git_repository> -d <chart_dir>
# Once synchronised, connect to the ArgoCD GUI to explore the project.

# Initialise
. common/init.sh

# Parse options
while getopts ":a:R:r:d:s:n:p:h" opt; do
    case ${opt} in
        h )
            print_app_options
            exit 0
            ;;
        a )
            APP_NAME=${OPTARG}
            ;;
        R )
            APP_RELEASE_NAME=${OPTARG}
            ;;
        r )
            APP_REPO=${OPTARG}
            ;;
        d )
            APP_PATH=${OPTARG}
            ;;
        s )
            APP_DEST_SERVER=${OPTARG}
            ;;
        n )
            APP_DEST_NAMESPACE=${OPTARG}
            ;;
        p )
            APP_PROJECT=${OPTARG}
            ;;
        \? )
            echo "Invalid option: -$OPTARG" 1>&2
            echo "\n"
            print_app_options
            exit 1
            ;;
    esac
done

if [ "$(check_cluster_status $KIND_CLUSTER)" ]; then
    if [ "$(check_namespace) $ARGO_NAME" ]; then
        info "attempting to add $APP_NAME and sync with ArgoCD"

        create_argocd_app || \
            err "failed to create and retrieve the $APP_NAME application"

        sync_agrocd_app || \
            err "failed to deploy $APP_NAME"
    fi
fi
