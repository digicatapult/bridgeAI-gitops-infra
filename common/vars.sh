#!/bin/bash

# Declare common variables
LOG_FILE="${LOG_FILE:-"$PWD/gitops-infra.log"}"

KIND_CONTEXT="${KIND_CONTEXT:-"mlops"}"  # the base MLOps context
KIND_CLUSTER="${KIND_CLUSTER:-"$KIND_CONTEXT"}"  # the cluster name
KIND_IMAGE="${KIND_IMAGE:-"kindest/node:v1.30.0"}"

ARGO_CLUSTER="${ARGO_CLUSTER:-"$KIND_CONTEXT"}"  # the cluster name
ARGO_NAME="${ARGO_NAME:-"argocd"}"  # the namespace
ARGO_PORT="${ARGO_PORT:-8080}"  # if accessing localhost:8080
ARGO_SECRET="${ARGO_SECRET:-}"  # if blank, the password will be generated
