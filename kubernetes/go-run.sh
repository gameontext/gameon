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
COREPROJECTS="auth map mediator player proxy room swagger webapp"

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

rebuild() {
  PROJECTS=''

  while [[ $# -gt 0 ]]; do
    case "$1" in
      all) PROJECTS="$COREPROJECTS $PROJECTS";;
      *) PROJECTS="$1 $PROJECTS";;
    esac
    shift
  done

  echo "Building projects [$PROJECTS]"
  for project in $PROJECTS
  do
    echo
    echo "*****"

    if [ ! -d "${project}" ]; then
      continue
    fi

    if [ -e "${project}/build.gradle" ]; then
      echo "Building project ${project} with gradle"

      cd "$project"
      ./gradlew build --rerun-tasks
      rc=$?
      if [ $rc != 0 ]; then
        echo Gradle build failed. Please investigate, Game On! is unlikely to work until the issue is resolved.
        exit 1
      fi

      # Build Docker image
      echo "Building docker image for ${project}"
      ./gradlew build image
    elif [ -d "${project}" ] && [ "${project}" == "webapp" ] && [ -f ${GO_DIR}/webapp/build.sh ]; then
      echo "webapp source present:  $(ls -d ${GO_DIR}/webapp/app)"
      ${GO_DIR}/webapp/build.sh
      ${GO_DIR}/webapp/build.sh final
    else
      echo "Re-building docker image for ${project}"
      cd "$project"
      ${DOCKER_CMD} build -t gameontext/gameon-${project} .
    fi

    cd ${GO_DIR}
  done
}

usage() {
  echo "
  Actions:
    setup    -- set up k8s secrets, prompt for helm
    reset    -- replace generated files (cert, config with cluster IP)
    env      -- eval-compatible commands to create aliases
    host     -- manually set host information about your k8s cluster

    up       -- install/update gameon-system namespace
    down     -- delete the gameon-system namespace
    status   -- return status of gameon-system namespace
    wait     -- wait until the game services are up and ready to play!

    mini-istio -- minikube start with parameters for istio
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
    reset
  ;;
  rebuild)
    rebuild $@
  ;;
  status)
    wrap_kubectl -n gameon-system get all

    get_cluster_ip
    echo "
    When ready, the game is available at https://${GAMEON_INGRESS}/
    "
  ;;
  mini-istio)
    wrap_minikube start \
      --extra-config=controller-manager.ClusterSigningCertFile="/var/lib/localkube/certs/ca.crt" \
      --extra-config=controller-manager.ClusterSigningKeyFile="/var/lib/localkube/certs/ca.key" \
      --extra-config=apiserver.Admission.PluginNames=NamespaceLifecycle,LimitRanger,ServiceAccount,PersistentVolumeLabel,DefaultStorageClass,DefaultTolerationSeconds,MutatingAdmissionWebhook,ValidatingAdmissionWebhook,ResourceQuota \
      --kubernetes-version=v1.9.0 \
      --memory 8192
  ;;
  env)
    echo "alias go-run='${SCRIPTDIR}/go-run.sh';"
    echo "alias go-admin='${GO_DIR}/go-admin.sh'"
  ;;
  wait)
    get_cluster_ip

    if kubectl -n gameon-system get po | grep -q mediator; then
      echo "Waiting for gameon-system pods to start"
      wait_until_ready -n gameon-system get pods
      echo ""
      echo "Game On! You're ready to play: https://${GAMEON_INGRESS}/"
    else
      echo "You haven't started any game services"
    fi
  ;;
  *)
    usage
  ;;
esac
