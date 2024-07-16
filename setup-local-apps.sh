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
while getopts ":a:R:r:d:s:n:p:P:h" opt; do
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
        P )
            APP_PORT=${OPTARG}
            ;;
        \? )
            echo "Invalid option: -$OPTARG" 1>&2
            echo "\n"
            print_app_options
            exit 1
            ;;
    esac
done

if [ -n "$APP_NAME" ]; then
    if [ ! "$(argocd app list | grep $APP_NAME)" ]; then
        if [ "$(check_cluster_status $KIND_CLUSTER)" ]; then
            info "attempting to add $APP_NAME and sync with ArgoCD"

            create_argocd_app || \
                err "failed to create and retrieve the $APP_NAME application"

            sync_agrocd_app || \
                err "failed to deploy $APP_NAME"
        fi
    else
        info "existing application entry found for $APP_NAME"
    fi
fi

if [ "$(kubectl get svc -n $ARGO_NAME | grep $APP_PORT)" ]; then
    until kubectl wait --for=condition=ready pods --all -n "$ARGO_NAME" \
        --timeout=10m &>/dev/null; do
        :
    done

    if [ "$APP_PORT" -ne "$ARGO_PORT" ]; then
        until lsof -i:"$APP_PORT" | grep LISTEN; do
            kubectl port-forward svc/airflow-web \
                -n "$ARGO_NAME" "$APP_PORT:8080" &>/dev/null &
        done

        info "tests finished; the Airflow interface is ready on $APP_PORT"
    else
        err "the Airflow GUI port is identical to ArgoCD's own"
    fi
fi
