#!/usr/bin/env bash

set -eu

AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}"
AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}"
AWS_SESSION_TOKEN="${AWS_SESSION_TOKEN}"
AWS_CONTROL_PLANE_MACHINE_TYPE="${AWS_CONTROL_PLANE_MACHINE_TYPE:-'t3.large'}"
AWS_NODE_MACHINE_TYPE="${AWS_NODE_MACHINE_TYPE:-'t3.large'}"
AWS_SSH_KEY_NAME="${AWS_SSH_KEY_NAME:-'fer'}"
AWS_REGION="${AWS_REGION:-'eu-west-1'}"

if [[ -z "${AWS_REGION}" ]]; then
  printf "No AWS_REGION var supplied\n"
  exit 0
fi

if [[ -z "${AWS_ACCESS_KEY_ID}" ]]; then
  printf "No AWS_ACCESS_KEY_ID var supplied\n"
  exit 0
fi

if [[ -z "${AWS_SECRET_ACCESS_KEY}" ]]; then
  printf "No AWS_SECRET_ACCESS_KEY var supplied\n"
  exit 0
fi

if [[ -z "${AWS_SESSION_TOKEN}" ]]; then
  printf "No AWS_SESSION_TOKEN var supplied\n"
fi


# 1.1 Install CAPI controllers (Manual)

# 1.1.1 (Optional) add IAM policies

printf "\n\e[32m-> Bootstrarp AWS account with needed roles for CAPI\e[0m\n"
# UNCOMMENT line below if it is first time you run it against the selected AWS account
# clusterawsadm bootstrap iam create-cloudformation-stack
export AWS_B64ENCODED_CREDENTIALS=$(clusterawsadm bootstrap credentials encode-as-profile)

# 1.1.2 Install the controllers
printf "\n\e[32m-> Deploy CAPI controllers in the mgmt cluster\e[0m\n"
clusterctl init --infrastructure aws

# 1.2. Install CAPI controllers (Helm)
# helm template capa --namespace capi --repo https://giantswarm.github.io/control-plane-test-catalog cluster-api-provider-aws --values mgmt-values.yaml | kubectl apply -f -

# helm template capi --namespace capi --repo https://giantswarm.github.io/control-plane-test-catalog cluster-api-core --values mgmt-values.yaml | kubectl apply -f -

# 2.Install App Operator and chart app for the managed cluster

printf "\n\e[32m-> Install app operator in mgmt cluster\e[0m\n"
apptestctl bootstrap --kubeconfig="$(kind get kubeconfig)"

printf "\n\e[32m-> Creating the chart operator app CR referencing new cluster\e[0m\n"
kubectl apply -f app-operator/catalog.yaml
kubectl apply -f app-operator/chart-operator.yaml

# 3.Install ACK controller
printf "\n\e[32m-> Install AWS ACK operator in mgmt cluster\e[0m\n"
kubectl apply -f ack/ack-s3-controller/crds
helm template s3 ack/ack-s3-controller --set keyID="$AWS_ACCESS_KEY_ID" --set awsSecret="$AWS_SECRET_ACCESS_KEY" | kubectl apply -f -

printf "\n\e[32m-> Installation done, Management cluster ready to use!\e[0m\n"
