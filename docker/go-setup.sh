#!/bin/bash

# Support environments with docker-machine
# For base linux users, 127.0.0.1 is fine, but w/ docker-machine we need to
# use the host ip instead. So we'll generate an over-ridden env file that
# will get passed/copied properly into the target servers
#
# Use this script when you're developing rooms, or a subset of
# Game On services
#
# One-time, initial setup
#

SCRIPTDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $SCRIPTDIR/go-common

# Ensure we're executing from project root directory
cd "${SCRIPTDIR}"/..

NAME=${DOCKER_MACHINE_NAME-empty}
IP=127.0.0.1
if [ "$NAME" = "empty" ]
then
  echo "DOCKER_MACHINE_NAME is not set. If you don't use docker-machine, you can ignore this, or
  export DOCKER_MACHINE_NAME=''"
elif [ "$NAME" == "vagrant" ]
then
  if [ ! -f gameon.${NAME}env ]
  then
    echo "Creating new environment file gameon.${NAME}env to contain environment variable overrides.
          This file will use the docker host ip address ($IP), but will re-map ports for forwarding from the VM."
    cat gameon.env | sed -e 's/FRONT_END_\\(.*\\)127.0.0.1\\(.*\\)/FRONT_END_\\1127.0.0.1:9943\\2/g' > gameon.${NAME}env
  fi
elif [ "$NAME" != "" ]
then
  IP=$(docker-machine ip $NAME)
  rc=$?
  if [ $rc -ne 0 ] || [ -z ${DOCKER_HOST} ]
  then
    echo "Is your docker host running? Did you start docker-machine, e.g.
  docker-machine start default
  eval \$(docker-machine env default)"
    exit 1
  fi
  if [ ! -f gameon.${NAME}env ]
  then
    echo "Creating new environment file gameon.${NAME}env to contain environment variable overrides.
This file will use the docker host ip address ($IP).
When the docker containers are up, use https://$IP/ to connect to the game."
  fi
  cat gameon.env | sed  -e "s#127\.0\.0\.1\:6379#A8LOCALHOSTPRESERVE#g" | sed -e "s#127\.0\.0\.1#${IP}#g" | sed -e "s#A8LOCALHOSTPRESERVE#127\.0\.0\.1\:6379#" > gameon.${NAME}env
fi

ensure_keystore

${COMPOSE} pull
rc=$?
if [ $rc -ne 0 ]
then
  echo "Trouble pulling core images, we need to sort that first"
  exit 1
fi

${SCRIPTDIR}/go-run.sh rebuild_only

echo "

Start the Game On! platform:
  ./go-admin.sh up
OR:
  ./docker/go-run.sh up

Check for all services being ready:
  https://${HTTP_HOSTPORT}/site_alive

Wait for all game services to finish starting:
  ./docker/go-run.sh wait

If you are editing/updating core game services, rebuild and launch using:
  ./docker/go-run.sh rebuild all

The game will be running at https://${HTTPS_HOSTPORT}/ when you're all done.

"
