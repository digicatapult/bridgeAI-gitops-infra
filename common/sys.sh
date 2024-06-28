#!/bin/bash

# Define logging patterns
log() {
    if [ -z "$LOG_FILE" ]; then
        LOG_FILE="$PWD/gitops-infra.log"
    fi
    echo "$(date -R) ### $@" | tee -a "$LOG_FILE"
}

err() {
    log "error: $@; exiting"
    exit 1
}

warn() {
    log "warning: $@"
}

info() {
    log "info: $@"
}

dbg() {
    log "debug: $@"
}

# Check system configuration
check_dependencies() {
    dependencies=()
    for d in argocd docker kind kubectl; do
        which "$d" &>/dev/null || dependencies+=("$d")
    done

    if [ -n "$dependencies" ]; then
        err "these dependencies are missing: $dependencies"
    fi
}
