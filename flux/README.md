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

To check the state of the minio pod:

    kubectl get pods -n <<namespace>>


To see the detailed info on the pod status:

    kubectl describe pod/<<podname>> -n <<namespace>>

    kubectl logs pod/<<podname>> -n <<namespace>>


To access MinIO UI perform port forwarding on the pod:

    kubectl port-forward pod/<<podname>> 9000 9090 -n <<namespace>>

Reference:
https://min.io/docs/minio/kubernetes/upstream/index.html

Note: We use MLFLow's MinIO and not a separate instance of MinIO


## KServe

### KServe Prerequisites:

1. Ingress

2. Cert Manager



### Setup in order:

1. Ingress setup

2. Cert Manager setup

3. Kserve-crd setup

4. Kserve-resources setup

5. Create s3 secret and attach to service account for inferencing

6. Create inference service

7. Test inference service


### Setup & Testing steps:

1. KServe helm charts:

    kserve-crd: https://github.com/kserve/kserve/tree/master/charts/kserve-crd

    kserve-resources: https://github.com/kserve/kserve/tree/master/charts/kserve-resources

    Note: kserve-crd is to be setup first before setting up kserve-resources.

2. Once cert manager and kserve setup is completed. Run the below commands to check if kustomization resources and helm installations are in "Ready" state.

        kubectl get kustomizations -A

        kubectl get helmrelease -A

3. Check if the KServe CRD is installed, "servingruntimes.serving.kserve.io"

        kubectl get crd -A

4. Check if the Kserve inference service is in "Ready" state.

        kubectl get svc <<kserve-servicename>> -n <<namespace>>

        kubectl describe svc <<kserve-servicename>> -n <<namespace>>

5. Test the inference service.

    5.1 Prepare input json file (check references section on how to prepare)

    5.2 Pass inference request

        SERVICE_HOSTNAME=$(kubectl get inferenceservice <<inference-servicename>> -n default -o jsonpath='{.status.url}' | cut -d "/" -f 3)


        curl -v \  	-H "Host: ${SERVICE_HOSTNAME}" \  	-H "Content-Type: application/json" \  	-d @./<<input-filename>>.json \  	http://127.0.0.1:8081/v2/models/<<inference-servicename>>/infer

References:

KServe get started: 
https://kserve.github.io/website/latest/get_started/

Cert Manager helm chart can be found here: 
https://cert-manager.io/docs/installation/helm/

KServe prod installation: 
https://kserve.github.io/website/0.9/admin/kubernetes_deployment/#recommended-version-matrix

Create S3 Secret and attach to Service Account:
https://kserve.github.io/website/0.7/modelserving/storage/s3/s3/#attach-secret-to-a-service-account

Using MLFlow with KServe:
https://kserve.github.io/website/0.10/modelserving/v1beta1/mlflow/v2/#model-settings
https://mlflow.org/docs/latest/deployment/deploy-model-to-kubernetes/tutorial.html

### Cleanup

To delete a cluster

    kind delete clusters clustername

Verify if cluster is deleted

    kubectl config get-contexts