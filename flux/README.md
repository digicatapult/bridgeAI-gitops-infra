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

#### MinIO

MinIO is used as the storage backend to store MLFlow's artifacts

To access MinIO UI perform port forwarding on the pod:

    kubectl port-forward pod/<<podname>> 9000 9090 -n <<namespace>>

Access MinIO UI on: http://127.0.0.1:9001

Note: We use MLFLow's MinIO and not a separate instance of MinIO


### KServe


#### Create inference service

1. create an inference yaml file


        apiVersion: "serving.kserve.io/v1beta1"
        kind: "InferenceService"
        metadata:
        name: "house-price" # name of the inference service
        annotations:
            serving.kserve.io/deploymentMode: RawDeployment # deployment mode for production installation
            serving.kserve.io/disableIngressCreation: "true" # disable ingress creation for this service
        spec:
        predictor:
            serviceAccountName: inference-sa # service account to be used to access the model in a bucket, eg: MinIO
            model:
            modelFormat:
                name: mlflow # specifies the model format as mlflow
            protocolVersion: v2  # specifies the protocol version to use
            storageUri: s3://mlflow/0/1f5d520bc53a4e6ca119d333e80fad69/artifacts/model # S3 storage URI for the model in the bucket, e.g. MinIO

2. apply the inference yaml file

        kubectl apply -f <<filename>>.yaml


3. Check if the Kserve inference service is in "Ready" state.
    
        kubectl get svc <<kserve-servicename>> -n <<namespace>>

#### Test the inference service

1. Prepare input json file (check references section on how to prepare)

2. Port forward on the inference pod

        kubectl port-forward pods/<<podname>> 8081:8080

2. Pass inference request from terminal

        SERVICE_HOSTNAME=$(kubectl get inferenceservice <<inference-servicename>> -n default -o jsonpath='{.status.url}' | cut -d "/" -f 3)


        curl -v \  	-H "Host: ${SERVICE_HOSTNAME}" \  	-H "Content-Type: application/json" \  	-d @./<<input-filename>>.json \  	http://127.0.0.1:8081/v2/models/<<inference-servicename>>/infer

References: 
https://kserve.github.io/website/0.10/modelserving/v1beta1/mlflow/v2/#deploy-with-inferenceservice

### Cleanup

To delete a cluster

    kind delete clusters clustername

Verify if cluster is deleted

    kubectl config get-contexts