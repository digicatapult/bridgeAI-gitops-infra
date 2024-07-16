#!/bin/bash

# Manage ArgoCD projects and applications
check_argocd_project() {
    if [ -n "$APP_PROJECT" ]; then
        argocd proj list | grep "$APP_PROJECT" &>/dev/null || \
            argocd proj create "$APP_PROJECT" || \
                err "failed to create the $APP_PROJECT project"

        info "project $APP_PROJECT has been created"
    fi
}

create_argocd_app() {
    check_argocd_project

    if [ -n "$APP_REPO" ] && [ -n "$APP_NAME" ]; then
        argocd app create "$APP_NAME" \
            --repo "$APP_REPO" \
            --path "$APP_PATH" \
            --dest-server "$APP_DEST_SERVER" \
            --dest-namespace "$APP_DEST_NAMESPACE" \
            --release-name "$APP_RELEASE_NAME" \
            --project "$APP_PROJECT" \
            --upsert

        argocd app get "$APP_NAME"
    else
        err "expected a path to a Helm chart and name for the application"
    fi
}

sync_agrocd_app() {
    argocd app sync "$APP_NAME" || \
        err "failed to synchronise $APP_NAME resources"

    until kubectl wait --for=condition=ready pods --all \
        -n "$APP_DEST_NAMESPACE" --timeout=10m &>/dev/null; do
            :
    done

    info "$APP_NAME has synchronised with the upstream repository and is ready"
}
