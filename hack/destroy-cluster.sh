#!/bin/bash

ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"/..
TOOLCHAIN_E2E_TEMP_DIR=/tmp/toolchain-e2e

# Remove resources in the reverse order from bootstrapping

ARGO_CD_ROUTE=$(kubectl get \
                 -n openshift-gitops \
                 -o template \
                 --template={{.spec.host}} \
                 route/openshift-gitops-server \
               )
ARGO_CD_URL="https://$ARGO_CD_ROUTE"

# there is an issue with deletion of chains-pods
function wait_and_delete_chains {
  sleep 10
  oc delete -n tekton-chains --force pod --all
}
wait_and_delete_chains &

echo
echo "Starting with removing application, you can see progress $ARGO_CD_URL"
echo "If there is running Sync then cancel it manually"
echo "Remove Argo CD Applications:"
kubectl delete -f $ROOT/argo-cd-apps/app-of-apps/all-applications-staging.yaml
#kubectl -k $ROOT/argo-cd-apps/overlays/staging

echo
echo "Remove RBAC for OpenShift GitOps:"
kubectl delete -k $ROOT/openshift-gitops/cluster-rbac

echo 
echo "Remove the OpenShift GitOps operator subscription:"
kubectl delete -f $ROOT/openshift-gitops/subscription-openshift-gitops.yaml

echo 
echo "Removing operators and operands:"
oc delete clusterserviceversions.operators.coreos.com --all -n openshift-operators

echo
echo "Removing custom projects"
oc delete project enterprise-contract-service gitops quality-dashboard

echo
echo "Remove Toolchain (Sandbox) Operators with the user data:"
rm -rf ${TOOLCHAIN_E2E_TEMP_DIR} 2>/dev/null || true
git clone --depth=1 https://github.com/codeready-toolchain/toolchain-e2e.git ${TOOLCHAIN_E2E_TEMP_DIR}
make -C ${TOOLCHAIN_E2E_TEMP_DIR} appstudio-cleanup

echo 
echo "Complete."
