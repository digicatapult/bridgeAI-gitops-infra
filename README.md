# BridgeAI-gitops-infra

## Prerequisities

Ensure you have the following installed:
* kind
* kubectl
* flux
* gnupg
* [jq](https://jqlang.github.io/jq/) this one or the brew formula
* github cli

```
brew install kind kubectl fluxcd/tap/flux gnupg jq gh
```

## Getting started

Run the `./scripts/add-kind-cluster.sh` script.

You will need to setup a CLASSIC github personal access token that has `repo` and `package:read` permissions.

Select the GitOps branch you wish to track and run `./scripts/install-flux.sh -b <branch>`

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

To access MinIO UI perform port forwarding on the svc:

    kubectl port-forward svc/mlflow-minio 9001 -n default

Access MinIO UI on: http://127.0.0.1:9001
Username: admin
Password: password

Note: We use MLFLow's MinIO and not a separate instance of MinIO


### Prediction Service

The Prediction service is a REST API for interfacing with the house-price prediction inference service. It is presented as a swagger UI and is available at http://localhost:3080/swagger

### KServe

1. Before creating the inference service, Airflow DAGs needs to be run and a model should be available in MLFlow.
2. These DAGs in Airflow (data_ingestion_dag, model_training_dag) needs to run in sequence. Start the 2nd DAG only when 1st DAG is completed. 
3. Once the DAG run is completed an experiment will be created in MLFlow. An experiment contains a model file. Get the URI of the model and this URI needs to be added to the inference.yaml file. e.g of URI - mlflow-artifacts:/0/e7750463f06145d39a085ad7d9a55cb9/artifacts/model
4. Part of the URI after "mlflow-artifacts:/" is to be updated in the inference.yaml file.


#### Create inference service

1. create an inference.yaml file similar to below, you may need to update the image to be specific to whatever registry you pushed to.

```yaml
apiVersion: "serving.kserve.io/v1beta1"
kind: "InferenceService"
metadata:
  name: "house-price"
  namespace: "default"
  annotations:
      serving.kserve.io/deploymentMode: RawDeployment
      serving.kserve.io/disableIngressCreation: "true"
      serving.kserve.io/disableIstioVirtualHost: "true"
spec:
  predictor:
    serviceAccountName: "inference-sa" #We use a specific SA so that we can attach secrets for retrieving the ECR container
    minReplicas: 1
    maxReplicas: 1
    containers:
      - name: "house-price"
        image: "058264114863.dkr.ecr.eu-west-2.amazonaws.com/bridgeai-mlops:latest" #The location of wherever you push the container to from airflow.
        ports:
          - containerPort: 8080
            protocol: TCP
        env:
          - name: PROTOCOL
            value: "v2"
```

2. apply the inference.yaml file

        kubectl apply -f inference.yaml


3. Check if the inference service is in "Ready" state.
    
        kubectl get inferenceservice house-price -n default

#### Test the inference service
TODO: Remove and replace with swagger UI.
1. Prepare input json file (check references section on how to prepare)

2. Port forward on the inference pod

        kubectl port-forward pods/<<podname>> 8081:8080

2. Pass inference request from terminal

        SERVICE_HOSTNAME=$(kubectl get inferenceservice house-price -n default -o jsonpath='{.status.url}' | cut -d "/" -f 3)


        curl -v \  	-H "Content-Type: application/json" \  	-d @./<<input-filename>>.json \  	http://127.0.0.1:8081/v2/models/house-price/infer

References: 
https://kserve.github.io/website/0.10/modelserving/v1beta1/mlflow/v2/#deploy-with-inferenceservice

### Cleanup

To delete a cluster

    kind delete clusters bridgeai-gitops-infra

Verify if cluster is deleted

    kubectl config get-contexts