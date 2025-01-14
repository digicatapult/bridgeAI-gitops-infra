# Creating a new production cluster

## Quickstart

### Prerequisites

- A Kubernetes cluster - It is recommended that you setup this cluster using terraform as described [here](https://github.com/digicatapult/bridgeAI-tf-infra)
- openssl or some other method of creating rsa keys (Github Deploy key is fine).

### Procedure

Work in progress

<!-- Copied from `wasp-k8s-infra` This will likely be close to the final form but will need updating once we have working cluster -->
<!-- Copy the `stage-cluster` directory and name it something else.  You can delete all the subfolders of the `app/env-services` directory as these are unnecessary.  Once removed also delete them from the `kustomization.yaml` and the corresponding lines related to their configmaps.

You will also need to edit:
* `clusters/<your-cluster>/app/shared-config/certificate.yaml` file and change:
    * `metadata.name` to a new certificate name
    * `spec.secretName` to the new secret you wish to store the cert as
    * `spec.subject.organizations` to the new Org
    * `spec.dnsNames` to the DNS names you want the cert to be valid for
* `clusters/<your-cluster>/app/shared-config/values-nginx.yaml` file and change:
    * `service.annotations` :
        * `external-dns.alpha.kubernetes.io/hostname` to specify the external DNS name you want to use.
        * any other annotations specified by your PaaS provider to setup.
        * Remove the AWS specific ones if not using AWS.
    * `extraArgs.default-ssl-certificate` to the `spec.secretName` we set in `certificates.yaml`
* `clusters/<your-cluster>/app/storage-class.yaml` - Remove all unnecessary storage classes using AWS CSI driver if you are not using this.
* `clusters/your-cluster/app/shared-config/` - In each of the services find mention of `storageClass` and either switch this to your own SC or delete the entry entirely.

Commit and push your changes. -->

#### Install flux onto your cluster

```
flux install
```

Generate an RSA keypair and make sure you give this `read access` as deployKey on Github or your git server.

```
openssl gen rsa -out id_rsa 4096
openssl rsa -in id_rsa -pubout -out id_rsa.pub
```

Install this keypair onto your k8s cluster and into your git server so we can pull flux repository.

Example below uses github as an example:

```
kubectl create secret generic --type=Opaque \
--namespace=flux-system flux-system \
--from-file=identity=./id_rsa \
--from-file=identity.pub=./id_rsa.pub \
--from-literal=known_hosts=github.com ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ==
```

Now delete the keypair from your machine:

```
rm -rf id_rsa*
```

#### Flux - git sources and kustomizations

Now that we have flux installed and a key that we can use to get the repository we need to make some changes to the source files to build your cluster.

Navigate to `flux/clusters/<your-cluster>/base/flux-system/` and edit `gotk-sync.yaml` to update

- `spec.url` to match your repo ssh location.
- `spec.ref.branch` to match the branch you are pushing to.
- `spec.path` in the Kustomization to match the path we are editing.

Once these changes have been made go ahead and commit them to git.

You'll now need to edit or remove the following kustomizations in `flux/clusters/<your-cluster>/base/`:

- app-sync.yaml - Required - change `spec.path`
- namespaces.yaml - Required - no changes
- infra-sync.yaml - Optional - installs various infrastructure change `spec.path` if you want to install all the base infrastructure components (ebs-csi-driver, cert-manager, cloudwatch) or delete if unnecassary
- secrets-sync.yaml - Required - change `spec.path`

Once again commit your changes and now push them to your remote branch.

Next up we will need to add the git source to flux on our cluster

```
flux create source git  --interval=1m \
--namespace=flux-system --secret-ref=flux-system \
--branch=<your branch> \
--url=<your git ssh url> flux-system
```

We should see that flux successfully creates and reconciles the source. If it fails to do so please check the [flux2 documentation](https://fluxcd.io/docs/) and check you have successfully installed the rsa key as a secret.

Providing the previous step succeeded then we need to add the kustomization.

```
flux create kustomization --interval=10m \
--namespace=flux-system \
--path=<the path to the flux-system folder> \
--prune --source=flux-system \
--validation=client flux-system
```

We should now have flux successully pulling and applying its initial `flux-system` kustomization. However the other kustomizations will fail due to a lack of secrets for the cluster.

#### Secrets

As mentioned in [managing secrets](./managing-secrets.md) we encrypt the secrets so that they can only be decrypted in cluster by the cluster.

##### PGP Key setup

Run the following commands to generate a PGP key

```
mktemp -d -t .sqnc-cluster-gpg

GNUPGHOME=.sqnc-cluster-gpg gpg \
--quick-gen-key --batch \
--passphrase '' --yes <cluster-name>
```

Export the public key as a certificate into the certs directory

```
mkdir certs/<cluster-name>

GNUPGHOME=.sqnc-cluster-gpg gpg \
--output certs/<cluster-name>/<cluster-name>.asc \
--export --armor <cluster-name>
```

Commit this and push it up to our branch.

We now need to import this key into the cluster

```
GNUPGHOME=.sqnc-cluster-gpg gpg \
--export-secret-keys \
--armor <cluster-name> \
| kubectl create secret generic sops-gpg \
--namespace=flux-system \
--from-file=sops.asc=/dev/stdin
```

Verify that our imported key has the correct length.

```
$ kubectl describe secrets -n flux-system sops-gpg
Name:         sops-gpg
Namespace:    flux-system
Labels:       <none>
Annotations:  <none>

Type:  Opaque

Data
====
sops.asc:  5046 bytes
```

Now delete the tmp dir we used to create the key

```
rm -rf .sqnc-cluster-gpg
```
