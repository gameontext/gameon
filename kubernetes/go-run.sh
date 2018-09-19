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

# set the action, default to help if none passed.
ACTION=help
if [ $# -ge 1 ]; then
  ACTION=$1
  shift
fi

usage() {
  echo "
  Actions:
    setup  -- set up k8s secrets, prompt for helm
    reset    -- reset generated files
    env      -- eval-compatible commands to create aliases
    host     -- manually set host information about your k8s cluster

    up       -- install/update gameon-system namespace
    down     -- delete the gameon-system namespace
    status   -- return status of gameon-system namespace
    wait     -- wait until the game services are up and ready to play!
  "
}

case "$ACTION" in
  reset)
    reset_go
  ;;
  setup)
    prepare
  ;;
  up)
    check_cluster_cfg
    platform_up
  ;;
  down)
    check_cluster_cfg
    platform_down
  ;;
  rebuild)
    rebuild $@
  ;;
  status)
    check_cluster_cfg
    if wrap_kubectl -n gameon-system get po | grep -q mediator; then
      wrap_kubectl -n gameon-system get all

      echo "
When ready, the game is available at https://${GAMEON_INGRESS}:${SECURE_INGRESS_PORT}/
"
    else
      echo "You haven't started any game services"
    fi
  ;;
  env)
    echo "alias go-run='${SCRIPTDIR}/go-run.sh';"
    echo "alias go-admin='${GO_DIR}/go-admin.sh'"
  ;;
  wait)
    check_cluster_cfg
    if wrap_kubectl -n gameon-system get po | grep -q mediator; then
      echo "Waiting for gameon-system pods to start"
      wait_until_ready -n gameon-system get pods
      echo ""
      echo "Game On! You're ready to play: https://${GAMEON_INGRESS}:${SECURE_INGRESS_PORT}/"
    else
      echo "You haven't started any game services"
    fi
  ;;
  host)
    check_cluster_cfg
    define_ingress
  ;;
  k)
    wrap_exec_kubectl -n gameon-system $@
  ;;
  i)
    get_istio_path
    wrap_exec_istioctl -n gameon-system $@
  ;;
  cert)
    check_cluster_cfg
    create_certificate
  ;;
  install_istio)
    check_cluster_cfg
    install_istio
  ;;
  purge_istio)
    purge_istio
  ;;
  *)
    usage
  ;;
esac
