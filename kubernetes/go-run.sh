#!/bin/bash

# Support environments with docker-machine
# For base linux users, 127.0.0.1 is fine, but w/ docker-machine we need to
# use the host ip instead. So we'll generate an over-ridden env file that
# will get passed/copied properly into the target servers
#
# Use this script when you're developing rooms, or a subset of
# Game On services
#
# This will help start/stop Game On services
#

SCRIPTDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# Ensure we're executing from project root directory
cd "${SCRIPTDIR}"/..

#set the action, default to help if none passed.
ACTION=help
if [ $# -ge 1 ]; then
  ACTION=$1
  shift
fi

NOLOGS=0
#-- Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
  "--nologs")
    NOLOGS=1
  ;;
  esac
  shift
done

platform_up() {
  if [ ! -f .setup ]; then
    setup
  fi
  kubectl create -f kubernetes/ingress.yaml
  kubectl create -f kubernetes/gameon-configmap.yaml
  kubectl create -f kubernetes/couchdb.yaml
  kubectl create -f kubernetes/kafka.yaml

  kubectl create -f kubernetes/auth.yaml
  kubectl create -f kubernetes/mediator.yaml
  kubectl create -f kubernetes/map.yaml
  kubectl create -f kubernetes/player.yaml
  kubectl create -f kubernetes/webapp.yaml
}

platform_down() {
  if [ ! -f .setup ]; then
    setup
  fi
  kubectl delete -f kubernetes/auth.yaml
  kubectl delete -f kubernetes/mediator.yaml
  kubectl delete -f kubernetes/map.yaml
  kubectl delete -f kubernetes/player.yaml
  kubectl delete -f kubernetes/webapp.yaml

  kubectl delete -f kubernetes/ingress.yaml
  kubectl delete -f kubernetes/gameon-configmap.yaml
  kubectl delete -f kubernetes/couchdb.yaml
  kubectl delete -f kubernetes/kafka.yaml
}

setup() {
  echo "Checking for kubectl connection.."
  kubectl cluster-info
  echo $?
  echo "Checking for gameon host env var"
  echo $GAMEON_HOST
  echo "Configuring ingress and config map with gameon host"
  echo "doing sed magic.. (todo)"
  echo "Ok.. so the sed magic isn't done yet, please edit kubernetes/gameon-configmap.yaml and kubernetes/ingress.yaml and alter 192.168.9.100 to match your target IP address for your kubernetes cluster"
  echo "Creating JWT certificate"
  openssl req -x509 -newkey rsa:4096 -keyout onlykey.pem -out onlycert.pem -days 365 -nodes
  cat onlycert.pem onlykey.pem cert.pem
  kubectl create configmap --namespace=gameon-system --from-file=cert.pem global-cert
  touch .setup
  echo "Setup complete."
}

usage() {
  echo "
  Actions:
    setup

    up
    down
  "
}

case "$ACTION" in
  setup)
    setup 
  ;;
  up)
    platform_up
  ;;
  down)
    platform_down
  ;;
  reset_kafka)
    reset_kafka
  ;;
  *)
  usage
  ;;
esac
