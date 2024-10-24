# Repository structure

This repository is structured as follows:
```
flux/
    clusters/
        bridgeai-prod/ #cluster specific configuration
            base/
                flux-system/ # flux-system components
                    gotk-components.yaml
                    gotk-sync.yaml
                    kustomization.yaml
                secrets-sync.yaml # kustomization for loading application secrets
            secrets/
                ghcr_token.yml # SOPs encrypted secrets
        ...
    certs/ # contains public keys for each environment
        bridageai-prod/
            sops.asc
docs/ # contains documentation references
scripts/ # contains scripts for spinning up a local kind cluster and encrypting secrets
```

## clusters

Contains per cluster configuration details and deployment `Kustomizations`. These are first broken down by environment (for example `kind-cluster`) and then into the `base` install and the application `secrets`.

### base

The `base` section describes the flux-system components and allows for the loading of secrets and cluster applications.

### secrets

Contains SOPs encrypted secrets which will be loaded into the cluster and decrypted from within the cluster. See [secrets](./managing-secrets) for how to create new secrets for an environment.

## certs

Contains public PGP certificates (keys) used to encrypt new secrets organised by the environments in which the corresponding private keys are deployed.

## docs

Contains documentation for the repository