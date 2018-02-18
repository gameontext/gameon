#!/bin/bash

# This will help start/stop Game On services using in a Kubernetes cluster.
#
# `eval $(kubernetes/go-run.sh env)` will set aliases to more easily invoke
# this script's actions from the command line.
#

SCRIPTDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $SCRIPTDIR/k8s-functions

# Ensure we're executing from project root directory
cd "${GO_DIR}"

GO_DEPLOYMENT=kubernetes

#set the action, default to help if none passed.
ACTION=help
if [ $# -ge 1 ]; then
  ACTION=$1
  shift
fi

platform_up() {
  if [ ! -f .gameontext.kubernetes ] || [ ! -f .gameontext.cert.pem ]; then
    setup
  else
    check_cluster
    get_cluster_ip
    check_global_cert
  fi

  if [ -f .gameontext.helm ];  then
    wrap_helm install --name go-system ./kubernetes/chart/gameon-system/
  else
    wrap_kubectl apply -R -f kubernetes/kubectl
  fi

  echo "To test for readiness: http://${GAMEON_INGRESS}/site_alive"
  echo 'To wait for readiness: ./kubernetes/go-run.sh wait'
  echo 'To type less: eval $(./kubernetes/go-run.sh env)'
}

platform_down() {
  if kubectl get namespace gameon-system > /dev/null 2>&1; then
    if [ -f .gameontext.helm ];  then
      wrap_helm delete --purge go-system
    else
      wrap_kubectl delete -R -f kubernetes/kubectl
    fi
    wrap_kubectl delete namespace gameon-system
  else
    ok "gameon-system stopped"
  fi
}

usage() {
  echo "
  Actions:
    setup
    reset
    env
    host

    up
    down
    status
    wait
  "
}

case "$ACTION" in
  reset)
    reset
    setup
  ;;
  setup)
    setup
  ;;
  up)
    platform_up
  ;;
  down)
    platform_down
  ;;
  host)
    ingress_host
  ;;
  status)
    wrap_kubectl get all --namespace=gameon-system
  ;;
  env)
    echo "alias go-run='${SCRIPTDIR}/go-run.sh';"
    echo "alias go-admin='${GO_DIR}/go-admin.sh'"
  ;;
  wait)
    get_cluster_ip
    echo "Waiting until http://${GAMEON_INGRESS}/site_alive returns OK."
    echo "This may take awhile, as it is starting a number of containers at the same time."

    until $(curl --output /dev/null --silent --head --fail http://${GAMEON_INGRESS}/site_alive 2>/dev/null)
    do
      printf '.'
      sleep 5s
    done
    echo ""
    echo "Game On! You're ready to play: https://${GAMEON_INGRESS}/"
  ;;
  *)
    usage
  ;;
esac
