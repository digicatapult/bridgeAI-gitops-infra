#!/bin/sh
set -o errexit

assert_command() {
  local command=$1

  printf "Checking for presense of $command..."
  local path_to_executable=$(command -v ${command})

  if [ -z "$path_to_executable" ] ; then
    echo -e "Cannot find ${command} executable. Is it on your \$PATH?"
    exit 1
  fi
  printf "OK\n"
}

for COMMAND in "kind" "docker" "kubectl"; do
    assert_command "${COMMAND}"
done

working_dir="$(dirname $(readlink -f $0))"
certs_dir="${working_dir}/../certs/kind"
auth_dir="${working_dir}/../auth"
mkdir -p {"$certs_dir","$auth_dir"}

# create registry container unless it already exists
# log in with the following: docker login localhost:5000
# the username and password credentials are listed below
reg_name='kind-registry'
reg_port='5000'
reg_username="localadmin"
reg_password="localpassword"
if [ -z "$(ls -A ${certs_dir})" ]; then
  openssl req -newkey rsa:2048 -nodes -sha256 \
    -keyout "${certs_dir}/${reg_name}.key" \
    -addext "subjectAltName = DNS:${reg_name}" \
    -batch -x509 -out "${certs_dir}/${reg_name}.crt"
fi
if [ -z "$(ls -A ${auth_dir})" ]; then
  docker run \
    --entrypoint htpasswd \
    httpd:2 -Bbn "${reg_username}" "${reg_password}" > "${auth_dir}/htpasswd"
fi
running="$(docker inspect -f '{{.State.Running}}' "${reg_name}" 2>/dev/null || true)"
if [ "${running}" != 'true' ]; then
  docker run \
    -d --restart=always -p "127.0.0.1:${reg_port}:5000" --name "${reg_name}" \
    -v "${certs_dir}:/certs" \
    -e REGISTRY_HTTP_TLS_CERTIFICATE="/certs/${reg_name}.crt" \
    -e REGISTRY_HTTP_TLS_KEY="/certs/${reg_name}.key" \
    -v "${auth_dir}:/auth" \
    -e "REGISTRY_AUTH=htpasswd" \
    -e "REGISTRY_AUTH_HTPASSWD_REALM=Registry Realm" \
    -e REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd \
    registry:2
fi

# create a cluster with the local registry enabled in containerd
cat <<EOF | kind create cluster --name bridgeai-gitops-infra --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
containerdConfigPatches:
- |-
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."localhost:${reg_port}"]
    endpoint = ["https://${reg_name}:${reg_port}"]
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 3080
    protocol: tcp
  - containerPort: 443
    hostPort: 3443
    protocol: tcp
- role: worker
EOF

# connect the registry to the cluster network
# (the network may already be connected)
docker network connect "kind" "${reg_name}" || true

# Document the local registry
# https://github.com/kubernetes/enhancements/tree/master/keps/sig-cluster-lifecycle/generic/1755-communicating-a-local-registry
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: local-registry-hosting
  namespace: kube-public
data:
  localRegistryHosting.v1: |
    host: "localhost:${reg_port}"
    help: "https://kind.sigs.k8s.io/docs/user/local-registry/"
EOF
