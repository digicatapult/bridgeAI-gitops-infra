# Flux Infra

## Prerequisities

Ensure you have the following installed:
* kind
* kubectl
* flux
* gnupg
* [jq](https://jqlang.github.io/jq/) this one or the brew formula
* github cli

## Getting started

Run the `./flux/scripts/add-kind-cluster.sh` script.

You will need to setup a CLASSIC github personal access token that has `repo` and `package:read` permissions.

Select the GitOps branch you wish to track and run `./flux/scripts/install-flux.sh -b <branch>`

This will bring up a kind cluster with flux installed and will automatically install nginx and airflow

### Airflow

You can access the airflow UI on http://localhost:3080/airflow
Username: admin
Password: admin

### MLFlow

You can access the MLFlow UI on http://localhost:3080/mlflow
No authentication required.
You can set the MLFLOW_TRACKING_URI clientside as http://localhost:3080/ Airflow has a variable set to locate the mlflow_tracking_uri