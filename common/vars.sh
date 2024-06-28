#!/bin/bash

# Declare common variables
LOG_FILE="${LOG_FILE:-"$PWD/gitops-infra.log"}"

KIND_IMAGE="${KIND_IMAGE:-"kindest/node:v1.30.0"}"

ARGO_PORT="${ARGO_PORT:-8080}"  # if accessing localhost:8080
ARGO_NAME="${ARGO_NAME:-"argocd"}"  # the cluster name
ARGO_CONTEXT="${ARGO_CONTEXT:-"kind-$ARGO_NAME"}"  # the kind context
ARGO_SECRET="${ARGO_SECRET:-}"  # if blank, the password will be generated
