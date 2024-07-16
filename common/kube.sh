#!/bin/bash

# Perform checks
check_cluster_status() {
    kind get clusters | grep "$@"
}

check_node_count() {
    kubectl get nodes | grep -ci ready
}

check_namespace() {
    kubectl get ns | grep "$@" || \
        info "namespace $@ does not exist"
}

use_kind_context() {
    context=$(kubectl config get-contexts | \
    grep -Eo "(kind-){1,}$KIND_CONTEXT" | head -n 1)
    if [ "$context" ]; then
        kubectl config use-context "$context" && \
            info "context is currently $context"
    fi
}

# Create a new cluster
create_argocd_cluster() {
    if [ "$(check_node_count)" -eq 0 ]; then
        err "no ready nodes were found; ArgoCD needs one"
    fi

    kind create cluster --name "$ARGO_CLUSTER" 2>/dev/null || \
        info "the $ARGO_CLUSTER context already exists; skipping"

    kubectl create namespace "$ARGO_NAME" || \
        err "failed to create a new ArgoCD namespace"

    kubectl apply -n "$ARGO_NAME" \
        -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
}

# Map services to localhost
map_argocd_server() {
    if [ "$(check_namespace $ARGO_NAME)" ]; then
        until kubectl wait --for=condition=ready pods --all -n "$ARGO_NAME" \
            --timeout=10m &>/dev/null; do
            :
        done

        if [ -n "$ARGO_PORT" ]; then
            until kubectl get svc -n "$ARGO_NAME" | grep "$ARGO_PORT"; do
                :
            done
            kubectl port-forward svc/argocd-server \
                -n "$ARGO_NAME" "$ARGO_PORT:443" &>/dev/null &
        else
            warn "missing variables to configure ports for ArgoCD"
        fi
    else
        err "no ArgoCD namespace found; cannot map ports without ArgoCD properly configured"
    fi
}

# Destroy clusters and namespaces
delete_argocd_cluster() {
    if [ "$(check_namespace $ARGO_NAME)" ]; then
        kubectl delete namespace "$ARGO_NAME"
        kubectl wait --for=delete ns "$ARGO_NAME" --timeout=60s || \
            warn "failed to delete the $ARGO_NAME namespace"
    fi

    if [ "$(check_cluster_status $ARGO_CLUSTER)" ]; then
        kind delete cluster --name "$ARGO_CLUSTER" || \
            warn "failed to delete the "$ARGO_CLUSTER" cluster"
    else
        info "no cluster matching '$ARGO_CLUSTER' was found"
    fi
}

# Test insecure log-in credentials
test_argocd_login() {
    if [ -z "$ARGO_SECRET" ]; then
        ARGO_SECRET=$(kubectl get secret \
            -n "$ARGO_NAME" argocd-initial-admin-secret \
            -o jsonpath="{.data.password}" | base64 -d)
        echo "The ArgoCD admin password is $ARGO_SECRET."
        echo "It can be changed with 'argocd account update-password'."
    fi

    if [ -n "$ARGO_PORT" ]; then
        argocd login localhost:"$ARGO_PORT" --insecure \
            --username admin --password "$ARGO_SECRET"
    fi
}
