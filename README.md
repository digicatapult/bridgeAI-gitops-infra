# BridgeAI-gitops-infra

## Prerequisities

A Linux or OSX Based computer with at least 16GB of RAM.

### Dependencies

Ensure you have the following installed:
* Docker
* kind
* kubectl
* flux
* gnupg
* [jq](https://jqlang.github.io/jq/) this one or the brew formula
* github cli

Ensure you have the following accounts:
* Github
* Dockerhub

You will need to setup a CLASSIC github personal access token that has `repo` and `package:read` permissions.  It will need to be set as an ENVAR that the CLI tools can access, we recommend either setting it in the terminal or as a part of your shell profile.

```
export GITHUB_TOKEN=<token>
```

You will also need a DockerHub account with a public repository setup that we can push containers to via an access token.

#### OSX
Install using homebrew:

```
brew install kind kubectl fluxcd/tap/flux@2.3 gnupg jq gh
```

You should install docker desktop from the Docker website.

#### Linux
Install the listed dependencies using a package manager of your choice.

### Useful Knowledge

Having an understanding of the following subjects will useful:
* Python
* Kubernetes
* Git
* Docker

## Getting started

Clone the repository.
```
git clone https://github.com/digicatapult/bridgeAI-gitops-infra.git
```

Ensure that the Docker engine has at least 12GB of RAM resourced to it and several GB of swap.

Run the `./scripts/add-kind-cluster.sh` script.

Select the GitOps branch you wish to track and run `./scripts/install-flux.sh -b <branch>`

This will bring up a kind cluster with flux installed and will automatically install nginx and airflow

Verify that all the helm charts have successfully installed
```
flux get helmreleases -A
```

### Local Workflow usage

See [local workflow](./docs/local-workflow.md) document for running the localised demonstrator.


### Local Application Instances

#### Airflow

You can access the airflow UI on http://localhost:3080/airflow
Username: admin
Password: admin

#### MLFlow

You can access the MLFlow UI on http://localhost:3080/mlflow
Username: admin
Password: password
You can set the MLFLOW_TRACKING_URI clientside as http://localhost:3080/ if you wish to use the mlflow binary clientside. Airflow has a variable set to locate the mlflow_tracking_uri

##### MLFlow MinIO

MinIO is used as the storage backend to store MLFlow's artifacts

To access MinIO UI perform port forwarding on the svc:
```
kubectl port-forward svc/mlflow-minio 9001 -n default
```
Access MinIO UI on: http://127.0.0.1:9001
Username: admin
Password: password

#### DVC and Evidently

We use a separate instance of MinIO as the storage backends for DVC data and Evidently reports.

To access this instance of MinIO UI perform port forwarding on the svc:

```
kubectl port-forward svc/minio 9002:9001 -n default
```
Access MinIO UI on: http://127.0.0.1:9002
Username: admin
Password: password

#### KServe

KServe is used as our model serving and inference framework.  We are using it in `rawDeployment` mode which means a container is spawned for running the model application.  This a Kubernetes `CRD` and can only be queried using kubectl commands.  You can see which CRDs can be queried using the `kubectl get crd |grep kserve` command.  We typically only make use of the `inferenceservices` CRD in this demonstrator.

#### Prediction Service

The Prediction service is a REST API for interfacing with the house-price prediction inference service. It is presented as a swagger UI and is available at http://localhost:3080/swagger

## Cleanup

To delete a cluster

    kind delete clusters bridgeai-gitops-infra

Verify if cluster is deleted

    kubectl config get-contexts