# Flux Infra

## Prerequisities

Ensure you have the following installed:
* kind
* kubectl
* flux
* gnupg
* github cli

## Getting started

Run the `./flux/scripts/add-kind-cluster.sh` script.

Select the GitOps branch you wish to track and run `./flux/scripts/install-flux.sh -b <branch>`

This will bring up a kind cluster with flux installed and will automatically install nginx and airflow

You can access the airflow UI on http://localhost:3080/airflow
Username: admin
Password: admin
