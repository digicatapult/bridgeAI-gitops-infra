#!/bin/bash

# Define logging patterns
log() {
    if [ "$ENABLE_LOGS" -eq 1 ]; then
        if [ -n "$LOG_FILE" ]; then
            echo "$(date -R) ### $@" | tee -a "$LOG_FILE"
        else
            warn "logging has been enabled, but no path was found"
        fi
    else
        echo "$(date -R) ### $@"
    fi
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

    docker info &>/dev/null || \
        err "Docker is not running, but its daemon is required for kind"
}
