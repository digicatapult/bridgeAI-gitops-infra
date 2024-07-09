# Bridge AI GitOps infra

This repository serves to create GitOps infrastructure using [ArgoCD][argo], to automate MLOps in an easily reproducible fashion.

There are several dependencies:
- `argocd`
- `docker`
- `kind`
- `kubectl`

Additional components will be added in due course, `helm` for example.


## Local deployments

To initialise ArgoCD locally, run the following:

```bash
git clone https://github.com/digicatapult/bridgeai-gitops-infra
cd bridgeai-gitops-infra
./setup-local-infra.sh
```

There are several options to help configure and monitor local infrastructure:
- `-n`: The Kubernetes namespace to use for ArgoCD
- `-p`: The port number for accessing the ArgoCD GUI over HTTP
- `-f`: The file path for logging messages from the various clusters
- `-l`: A flag to toggle logging on or off; if logging is toggled on without a given path, then a default location will be used instead: `$PWD/gitops-infra.log`

Once access to the ArgoCD GUI has been verified, the panel will be available on [localhost:8080][localhost].

Configurable variables can be found under `common/vars.sh`. A different port, other than 8080, can be provided with `ARGO_PORT`. Most of these have default values, except for `ARGO_SECRET`, the password generated for the administrator to log in via the ArgoCD GUI/CLI.

That password will be printed to standard out during the process, but it can also be recovered with the following:

```bash
kubectl get secret -n argocd \
    argocd-initial-admin-secret -o jsonpath="{.data.password}" | \
    base64 -d && echo
```

<!-- Links -->
[kind]: https://kind.sigs.k8s.io/
[argo]: https://argoproj.github.io/
[localhost]: http://localhost:8080/
