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

print_app_options() {
	echo "
This will create applications within the target namespace and project, pull
charts and manifests, and then synchronise with ArgoCD to facilitate GitOps
across the various project repositories.

Usage:

./add-local-app.sh [ -h ] [ -aRrdsnp ]

Options:

-a    The application name; this is required and there is no default.

-R    The release environment; this is optional.

-r    The Git repository containing the application's Helm chart and values.

-d    The path within that repository to find the above files.

-s    The target server for the application; the default is 'https://kubernetes.default.svc'.

-n    The target namespace; the default is 'default'.

-p    The name of the overarching project for the application; the default is 'mlops'.

Flags:

-h    Print this help message."
}
