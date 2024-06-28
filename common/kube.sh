#!/bin/bash

# Perform checks
check_cluster_status() {
    kubectl config get-contexts | grep "$@"
}

check_node_count() {
    kubectl get nodes | grep -ci ready
}

# Create a new cluster
create_argocd_cluster() {
    if [ "$(check_node_count)" -eq 0 ]; then
        err "no ready nodes were found; ArgoCD needs one"
    fi

    kind create cluster --name "$ARGO_NAME"

    kubectl create namespace "$ARGO_NAME" || \
        err "failed to create ArgoCD namespace"

    kubectl apply -n "$ARGO_NAME" \
        -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
}

# Map services to localhost
map_argocd_server() {
    if [ -n "$ARGO_PORT" ]; then
        kubectl port-forward svc/argocd-server \
            -n "$ARGO_NAME" "$ARGO_PORT:443" &>/dev/null &
    else
        warn "missing variables to configure ports for ArgoCD"
    fi
}

# Destroy clusters and namespaces
delete_argocd_cluster() {
    kubectl delete namespace "$ARGO_NAME" || \
        warn "failed to delete the $ARGO_NAME namespace"

    if [ "$(check_cluster_status $ARGO_NAME)" ]; then
        for context in "$ARGO_NAME" kind kind-kind; do
            kind delete cluster --name "$context" || \
                warn "failed to delete $context"
        done
    fi
}

# Test insecure log-in credentials
test_argocd_login() {
    if [ -z "$ARGO_SECRET" ]; then
        ARGO_SECRET=`kubectl get secret \
            -n "$ARGO_NAME" argocd-initial-admin-secret \
            -o jsonpath="{.data.password}" | base64 -d && echo`
    fi

    if [ -n "$ARGO_PORT" ]; then
        argocd login localhost:"$ARGO_PORT" --insecure \
            --username admin --password "$ARGO_SECRET"
    fi
}
