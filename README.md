# Bridge AI GitOps infra

This repository serves to create GitOps infrastructure using [ArgoCD][argo], to automate MLOps in an easily reproducible fashion.

There are several dependencies:
- `argocd`
- `docker`
- `kind`
- `kubectl`

Additional components will be added in due course, `helm` for example.


## Local deployments

### GitOps configuration

To initialise ArgoCD locally, run the following:

```bash
git clone https://github.com/digicatapult/bridgeai-gitops-infra
cd bridgeai-gitops-infra
./setup-local-infra.sh
```

There are several options to help configure and monitor local infrastructure:
- `-n`: The ArgoCD namespace
- `-c`: The Kind context to use for MLOps
- `-a`: The ArgoCD cluster name
- `-k`: The Kind cluster name
- `-p`: The port number for accessing the ArgoCD GUI over HTTP
- `-f`: The file path for logging messages from the various clusters
- `-l`: A flag to toggle logging on or off; if logging is toggled on without a given path, then a default location will be used instead: `$PWD/gitops-infra.log`

Taken altogether, this might be a typical setup:
```bash
./setup-local-infra.sh -c mlops -n argocd -p 8080 -f ./gitops-infra.log -l
```

Do note that Kind will insert the string "kind-" into certain names it generates behind the scenes, so that the context name "mlops" will become "kind-mlops".

Once access to the ArgoCD GUI has been verified, the panel will be available on [localhost:8080][localhost].

Configurable variables can be found under `common/vars.sh`. A different port, other than 8080, can be provided with `ARGO_PORT`. Most of these have default values, except for `ARGO_SECRET`, the password generated for the administrator to log in via the ArgoCD GUI/CLI.

That password will be printed to standard out during the process, but it can also be recovered with the following:

```bash
kubectl get secret -n argocd \
    argocd-initial-admin-secret -o jsonpath="{.data.password}" | \
    base64 -d && echo
```

### Application configuration

After the GitOps infrastructure itself has been configured, additional components can be synchronised with ArgoCD either with the `argocd` subcommands or managed via the `./setup-local-apps.sh` script.

Several arguments are needed for deploying applications:
- `-a`: The application name
- `-r`: The Git repository containing charts and manifests
- `-d`: The appropriate path within that repository
- `-p`: The project name to group applications
- `-P`: The application port

All other settings are considered optional:
- `-R`: The release name, for example 'airflow-test'; this defaults to the application name
- `-s`: The destination server for the application; the default is 'https://kubernetes.default.svc'
- `-t`: The target namespace; this is ordinarily 'default'

This example deployment will synchronise pipeline applications from "apps", such as Apache Airflow, with ArgoCD:

```bash
./setup-local-apps.sh -a "apps" -d "argo/apps" -p "default" \
    -s "https://kubernetes.default.svc" -n argocd \
    -r "https://github.com/digicatapult/bridgeai-gitops-infra.git"
```

Customised Helm charts and values can be used in place of any official company or community offerings. When adding new applications to ArgoCD, the path must resolve to wherever the charts are located. In this instance, there is a meta-application, "apps", containing multiple child applications that form the MLOps pipeline.

This wrapper script can also be used to stand up individual applications when logged into ArgoCD:

```bash
./setup-local-apps.sh -a "airflow" -d "charts/airflow" \
    -s "https://kubernetes.default.svc" -n argocd -P 8745 \
    -r "https://github.com/airflow-helm/charts.git"
```

<!-- Links -->
[kind]: https://kind.sigs.k8s.io/
[argo]: https://argoproj.github.io/
[localhost]: http://localhost:8080/
