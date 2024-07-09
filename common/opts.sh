#!/bin/sh

print_local_options() {
	echo "
This will install local ArgoCD infrastructure and configure MLOps services for
the Bridge AI demonstrator.

Usage:

./setup-local-infra.sh [ -h ] [ -np ] [ -l ]

Options:

-n    The name for the ArgoCD cluster; the default is 'argocd'.

-p    The port for HTTP access to the ArgoCD GUI; the default is 8080.

-f    The path for log files; this option is ignored without '-l'. Its default
value is '\$PWD/gitops-infra.log'.

Flags:

-l    Log messages to a file.

-h    Print this help message."
}
