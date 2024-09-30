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

### MinIO

MinIO is used as the storage backend to store MLFlow's artifacts

To access MinIO UI perform port forwarding on the pod:

    kubectl port-forward pod/<<podname>> 9000 9090 -n <<namespace>>

Reference:
https://min.io/docs/minio/kubernetes/upstream/index.html

Note: We use MLFLow's MinIO and not a separate instance of MinIO


## KServe


### Setup & Testing steps:

4. Check if the Kserve inference service is in "Ready" state.

        kubectl get svc <<kserve-servicename>> -n <<namespace>>

        kubectl describe svc <<kserve-servicename>> -n <<namespace>>

5. Test the inference service.

    5.1 Prepare input json file (check references section on how to prepare)

    5.2 Pass inference request

        SERVICE_HOSTNAME=$(kubectl get inferenceservice <<inference-servicename>> -n default -o jsonpath='{.status.url}' | cut -d "/" -f 3)


        curl -v \  	-H "Host: ${SERVICE_HOSTNAME}" \  	-H "Content-Type: application/json" \  	-d @./<<input-filename>>.json \  	http://127.0.0.1:8081/v2/models/<<inference-servicename>>/infer


### Cleanup

To delete a cluster

    kind delete clusters clustername

Verify if cluster is deleted

    kubectl config get-contexts