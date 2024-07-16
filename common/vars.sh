#!/bin/bash

# Declare common variables
ENABLE_LOGS="${ENABLE_LOGS:-0}"
LOG_FILE="${LOG_FILE:-"$PWD/gitops-infra.log"}"

KIND_CONTEXT="${KIND_CONTEXT:-"mlops"}"  # the base MLOps context
KIND_CLUSTER="${KIND_CLUSTER:-"$KIND_CONTEXT"}"  # the cluster name
KIND_IMAGE="${KIND_IMAGE:-"kindest/node:v1.30.0"}"

ARGO_CLUSTER="${ARGO_CLUSTER:-"$KIND_CONTEXT"}"  # the cluster name
ARGO_NAME="${ARGO_NAME:-"argocd"}"  # the namespace
ARGO_PORT="${ARGO_PORT:-8080}"  # if accessing localhost:8080
ARGO_SECRET="${ARGO_SECRET:-}"  # if blank, the password will be generated

APP_DEST_NAMESPACE="${APP_DEST_NAMESPACE:-"argocd"}"  # the target namespace
APP_DEST_SERVER="${APP_DEST_SERVER:-"https://kubernetes.default.svc"}"
APP_NAME="${APP_NAME:-}"  # the application's name
APP_PATH="${APP_PATH:-}"  # the path within the repository to its charts, manifests, and values
APP_PROJECT="${APP_PROJECT:-"default"}"  # a grouping for related components
APP_RELEASE_NAME="${APP_RELEASE_NAME:-"$APP_NAME"}"
APP_REPO="${APP_REPO:-}"  # the Git repository containing charts for the application
APP_PORT="${APP_PORT:-}"  # if accessing other consoles on localhost
