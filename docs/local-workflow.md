# Local workflow

To successfully create the MLOps pipeline we will need to run a series of Airflow DAGs, these are broken up into a few different stages.

## Data Ingestion
The first thing we need to do is to ingest the data we will be using to train and test our model.

1. [Fork](https://github.com/digicatapult/bridgeAI-regression-model-data-ingestion/fork) the [Data-ingestion](https://github.com/digicatapult/bridgeAI-regression-model-data-ingestion) repository, copying ALL branches.  As we will be pushing DVC metadata and tags to a branch in this fork.

2. Update the Airflow var `data_repo` to point to your forked repository, including the `.git` extension. e.g. `https://github.com/blah/bridgeAI-regression-model-data-ingestion.git`

3. Trigger the `data_ingestion_dag` from the [Airflow UI](../README.md#airflow). The source code for this DAG is available in [this repository](https://github.com/digicatapult/bridgeAI-regression-model-data-ingestion).  If you wish to read more about what it is doing.
Note that you can monitor the tasks in the DAG, view logs, etc, from the UI while it is running.

4. Once the DAG execution completes, a new data version like `data-v1.3.0` will appear in the Tags section of your forked repository similar to [this](https://github.com/digicatapult/bridgeAI-regression-model-data-ingestion/tags).

5. Make sure the `data_version` variable is updated to the new data version from step 4. after the DAG completes execution.  You should also now be able to find the model metadata in the `.dvc` folder in the newly created tag on your data repository.  The hash will correspond to data stored in [Minio](../README.md#dvc-and-evidently).

## Model Training

1. Trigger the `model_training_dag` from the [Airflow UI](../README.md#airflow). The source code that this DAG uses is located [here](https://github.com/digicatapult/bridgeAI-regression-model-training).  You can monitor the tasks in the DAG, view logs, etc., from the UI while it is running.

2. After the model training completes, the experiment should be available in the MLFlow UI.

3. Use the MLFlow UI to register and promote the model.
    * Browse to the [MLFlow experiment registry](http://localhost:3080/mlflow/#/experiments)
    * Select on the experiment that you wish to promote and click `Register Model`
    * Register the model with the name `house_price_prediction_prod`
    * Browse to the [MLFlow Models registry](http://localhost:3080/mlflow/#/models)
    * Click on the registered model named `house_price_prediction_prod`
    * Add the alias `champion` to the selected model version

## Model Image creation

1. Update the kubernetes secret `ecr-credentials` to contain your dockerhub registry login details.  We do this using the following code
```
kubectl create secret docker-registry ecr-credentials \
--docker-server=https://index.docker.io/v1/ \
--docker-username=<your docker registry username> \
--docker-password=<your docker registry token> \
--docker-email=<your email for the docker registry>
```

2. Trigger the `create_model_image_to_deploy_dag` from the [Airflow UI](../README.md#airflow). The source code for this DAG is in [this repository](https://github.com/digicatapult/bridgeAI-model-baseimage).  Monitor the tasks in the DAG, view logs, etc., from the UI while it is running.

3. Once this DAG completes, the model image will be pushed to the container registry you have previously specified.

## Model Deployment

1. We use the generated image to deploy the model using [Kserve](https://kserve.github.io/website/latest). You will need to update the image location to reflect the dockerhub account and repository you created earlier. `image: <dockerhub_username>/<mlflow_built_image_name>:<mlflow_built_image_tag>`. Deploying the model involves running the following command:
```
cat <<EOF |kubectl apply -f -
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
    serviceAccountName: "inference-sa" #We use a specific SA so that we can attach secrets for retrieving the container, if required.
    minReplicas: 1
    maxReplicas: 1
    containers:
      - name: "house-price"
        image: "digicatapult/bridgeai-mlops-image:latest" #The location of the container created in Model Image creation step
        ports:
          - containerPort: 8080
            protocol: TCP
        env:
          - name: PROTOCOL
            value: "v2"
EOF
```
2. We now verify that the model has been successfully deployed by querying the house-price `inferenceService` using the following command `kubectl get inferenceservices.serving.kserve.io` which should look like this.

```
NAME          URL                                      READY   PREV   LATEST   PREVROLLEDOUTREVISION   LATESTREADYREVISION   AGE
house-price   http://house-price-default.example.com   True                                                                  67m
```

## Prediction Service

1. You can access the Swagger UI and query the deployed model at `http://localhost:8000/swagger`.  You should run a few queries using the `/predict` POST endpoint.

## Drift Monitoring

1. Trigger the `drift_monitoring_dag` from the Airflow UI. The source code for this DAG is in [this repository](https://github.com/digicatapult/bridgeAI-drift-monitoring). Monitor tasks in the DAG and logs from the UI while it runs.

2. After execution, the report uploads to the specified S3 bucket. For local KIND clusters, it is the MinIO bucket `evidently-reports` in [Minio](../README.md#dvc-and-evidently).

3. Download the HTML [drift report](https://www.evidentlyai.com/ml-in-production/concept-drift) generated using [Evidently](https://www.evidentlyai.com).
