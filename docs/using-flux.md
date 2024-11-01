# Flux Usage

## Suspending/resuming flux

`fluxcd` is a tool used to manage the services deployed in your `Kind` cluster using `gitops`. It works by watching one or more paths on git repositories which describe the services that should be deployed in the cluster. When the values in the git repository change `flux` will reconcile those changes against your cluster which makes it easy to keep your development environment up-to-date. `flux` is also used in production environments to manage deployments so that manual intervention, beyond approving a pull-request, is not required to update a cluster.

What this does mean however is that a change to the repository state may cause your cluster to update services inconveniently whilst you are developing a change to a component. To combat this we can suspend the reconciliation of git repositories in your `flux` install. These can later be resumed when you would like your cluster to track repository state once again. In order to perform these actions you will need to have `flux` installed as described in [dependencies](#dependencies).

To view the current git repositories being synchronised you can call:

```console
$ flux get sources git
```

To then suspend reconciliation say the `flux-system` source call:

```console
flux suspend source git flux-system
```

A similar suspensions can be performed for other sources such as `Helm` repository sources and `Kustomization` sources. When you wish to resume reconciliation simply call:

```console
flux resume source git flux-system
```

## Dealing with unrecoverable Helm issues

During development you may find that helm reconciliation fails and does not resolve itself. This is likely due to either issues in `fluxcd` (which is at the time of writing in pre-release mode for v2) or issues with the Helm charts being deployed or their values. To see the status of helm releases it is easiest to run

```sh
flux get helmreleases -A
```

If a release is in an unrecoverable error state it can be resolved by removing the release resource and then allowing the Kustomization which deploys the release to reconcile. For example if the `demo-api` Helm release in the `test-application` namespace has erred you can run:

```sh
kubectl -n test-application delete helmrelease demo-api
```

and because this specific Helm release is deployed by the `app-deploy` Kustomization in the `flux-system` namespace we can reconcile with:

```sh
flux -n flux-system reconcile kustomization app-deploy
```

## Developing a new component service

When developing a new component service you need to ensure a few things:

- The service must be containerised and deployable using `helm`. This should be tested locally first using `helm install`.
- If a secret is required to pull the container image (perhaps it is in a private repository) then the secret resource must exist as a SOPs secret in each of the `/clusters/{CLUSTER_NAME}/secrets` directories

You will then need to define at least two custom resources for the new service in the `/shared` directory and a suitable application subdirectory.

First is the `HelmRepository` resource describing where the helm chart for the service is located. For example:

```yaml
---
apiVersion: source.toolkit.fluxcd.io/v1
kind: HelmRepository
metadata:
  name: demo-api
  namespace: test-application
spec:
  interval: 10m0s
  url: https://cdecatapult.github.io/5g-victori-demo-api
```

This instructs `flux` that it should examine this helm repository for packages that may be deployed as helm releases into its cluster.

The second resource is the `HelmRelease` that describes the actual service to deploy:

```yaml
apiVersion: helm.toolkit.fluxcd.io/v2beta2
kind: HelmRelease
metadata:
  name: demo-api
  namespace: test-application
spec:
  chart:
    spec:
      # `sourceRef` refers to the `HelmRepository` resource described above
      sourceRef:
        kind: HelmRepository
        name: demo-api
      # `chart` refers to the name of the chart to deploy from the repository
      # and `version` the specific version
      chart: stats-api
      version: "0.0.5"
  # secrets can be pulled in from sops secrets defined on a per-cluster basis
  # at /clusters/{CLUSTER_NAME}/secrets/api-redis-creds.yaml
  # The secrets must be present for all clusters!
  valuesFrom:
    - kind: Secret
      name: api-redis-creds
      valuesKey: password
      targetPath: global.redis.password
  # configuration values that apply to all clusters may be placed here. Per cluster configuration
  # should use a config map defined at /clusters/{CLUSTER_NAME}/base/config/{CONFIG_NAME}.yaml
  # and import it like:
  # valuesFrom:
  #   - kind: ConfigMap
  #     name: {CONFIG_RESOURCE_NAME}
  values:
    config:
      stats_queue_uri: kafka:9092
    kafka:
      enabled: false
    image:
      pullSecrets:
        - ghcr-cdecatapult
    ingress:
      annotations:
        kubernetes.io/ingress.class: nginx
        nginx.ingress.kubernetes.io/rewrite-target: /$2
      path: "/api(/|$)(.*)"
  interval: 10m0s
```

These resources may be defined in the same file or may be defined separately. You may also need one or more `ConfigMap` resources and one or more SOPs encrypted `Secret` resources in order for your service to deploy. This will depend on the specific configuration requirements of the service and will need to be added individually for each cluster.

To test your changes you will need to push them to a feature branch and instruct flux in your local cluster to sync from that branch. This must be done in two steps:

1. Modify the `spec->ref->branch` property of the `GitRepository` resource in [/flux/clusters/kind-cluster/base/flux-system/gotk-sync.yaml](`../flux/clusters/kind-cluster/base/flux-system/gotk-sync.yaml) to match your feature branch and push that change to your branch. Not doing this will cause flux to revert to syncing to `main` once it updates itself!
2. Update your local flux `GitRepository` resource to match the above. This is most easily done with the `flux` command line tool (substituting `{BRANCH_NAME}` appropriately):

```sh
flux create source git --branch {BRANCH_NAME} --namespace flux-system --url https://github.com/digicatapult/bridgeAI-gitops-infra.git flux-system
```

`flux` will now reconcile the changes with the existing deployment. The `flux` command line tool can also be used to check the status of syncing of different resources, pause/resume reconciliation (very helpful when debugging changes made locally) and forcing a sync (for those too impatient for polling `flux` does).

Once tested make sure the `branch` change in [/flux/clusters/kind-cluster/base/flux-system/gotk-sync.yaml](`../flux/clusters/kind-cluster/base/flux-system/gotk-sync.yaml) is reverted prior to merging to `main`.
