# Managing secrets

Secrets for the application are stored in repo as SOPs encrypted Kubernetes secrets. The keys for decrypting these secrets will be loaded into a cluster on creation and should never be retained on any other device. Public certificates (keys) corresponding to the decryption key are then stored in this repository under [certs](./repository-structure.md#certs) and can be used to encrypt new secrets for use by the deployed application.

## Creating new secrets

To create new secrets you will need to have [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) and [Mozilla SOPs](https://github.com/mozilla/sops). On MacOS these can both be installed using [Homebrew](https://brew.sh/).

To create a new secret you first need to generate the secret locally using `kubectl` then you will encrypt it with `SOPs`. As an example we will create an example of a `kubernetes.io/dockerconfigjson` secret for connecting to a docker registry and encrypting that for the `kind-cluster` deployment.

We can create a secret using:

```sh
kubectl create secret generic <secret-name> \
--namespace=<secret-namespace> \
--from-literal=<keyname>=<keydata>
--dry-run=client \
--output=yaml > ./clusters/inteli-stage/secrets/<secret-name>.unc.yaml
```

Replacing tags with appropriate values:

* `<secret-name>` is the name of the secret to create
* `<secret-namespace>` is the namespace in Kubernetes to create the secret in
* `<keyname>` is the name of the key we will store this data as
* `<keydata>` is the data that will be the secret.

This will generate the secret at the path `./clusters/inteli-stage/secrets/<secret-name>.unc.yaml` which should look something like

```yaml
apiVersion: v1
data:
  .testdata: dGVzdGRhdGEwMDE=¬
kind: Secret
metadata:
  creationTimestamp: null
  name: test-secret
  namespace: default
type: Opaque
```

Next we will need to encrypt the secret with SOPs. This can be done using the script `encrypt-secrets.sh` with the cluster to update as follows:

```sh
./scripts/encrypt-secrets.sh inteli-stage
```

This will ensure any unencrypted secrets in the cluster specific `secrets` directory are encrypted with all public keys configured for that cluster.