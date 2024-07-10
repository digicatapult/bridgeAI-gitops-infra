#!/bin/sh

print_local_options() {
	echo "
This will install local ArgoCD infrastructure and configure MLOps services for
the Bridge AI demonstrator.

Usage:

./setup-local-infra.sh [ -h ] [ -ncakpf ] [ -l ]

Options:

-n    The ArgoCD namespace; the default is 'argocd'.

-c    The Kubernetes context to use; the default is 'mlops' for 'kind-mlops'.

-a    The name for the ArgoCD cluster; it defaults to the context.

-k    The Kind MLOps cluster; it defaults to the context.

-p    The port for HTTP access to the ArgoCD GUI; the default is 8080.

-f    The path for log files; this option is ignored without '-l'. Its default
value is '\$PWD/gitops-infra.log'.

Flags:

-l    Log messages to a file.

-h    Print this help message."
}
