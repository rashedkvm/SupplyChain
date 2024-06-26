#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

SCRIPT_DIR=$(dirname "$0")
YTT_NAME_VALUE=my-dev


tanzu supplychain component list -w

kubectl delete namespace $YTT_NAME_VALUE --ignore-not-found=true

echo "executing in ... " $SCRIPT_DIR

kapp deploy -a supplychain-config --wait-timeout 5m -y -f <( ytt -f $SCRIPT_DIR/temp/values.yml -f $SCRIPT_DIR/config  -v name=$YTT_NAME_VALUE) -n default
# export TLS_CERTIFICATE_CRT="$(cat $SCRIPT_DIR/supplychain/v2/config/tls.crt | base64)"

kubectl patch serviceaccount default -p '{"secrets": [{"name": "oci-store-credentials"}, {"name": "gitlab-auth"}, {"name": "gitlab-cert"}]}' -n $YTT_NAME_VALUE

kapp deploy -a supplychain -n $YTT_NAME_VALUE --wait-timeout 5m -y \
-f $SCRIPT_DIR/components/source-git-provider-1.0.0.yaml \
-f $SCRIPT_DIR/supplychains/gitsource.yaml \
-f $SCRIPT_DIR/pipelines/source-git-provider.yaml \
-f $SCRIPT_DIR/tasks/
tanzu supplychain list -n $YTT_NAME_VALUE

kapp deploy -a workload -n $YTT_NAME_VALUE --wait-timeout 5m -y -f $SCRIPT_DIR/workload
tanzu workload list -n $YTT_NAME_VALUE
# tanzu workload get git-test -n $YTT_NAME_VALUE