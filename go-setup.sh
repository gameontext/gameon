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

NAME=${DOCKER_MACHINE_NAME-empty}
IP=127.0.0.1
if [ "$NAME" = "empty" ]
then
  echo "DOCKER_MACHINE_NAME is not set. If you don't use docker-machine, you can ignore this, or
  export DOCKER_MACHINE_NAME=''"
elif [ -n $NAME ]
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

SCRIPTDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
DOCKERPATHPREFIX=
docker version -f '{{.Client.Os}}' | grep windows
rc=$?
if [ $rc -eq 0 ]
then
  DOCKERPATHPREFIX=/
  sed -i 's/\r//' $SCRIPTDIR/gen-keystore.sh
fi

# If the keystore volume doesn't exist, then we should generate
# the keystores we need for local signed JWTs to work
docker volume inspect keystore &> /dev/null
rc=$?
if [ $rc -ne 0 ]
then
  docker volume create --name keystore
  # Dump cmd.. 
  echo docker run \
    -v keystore:/tmp/keystore \
    -v ${DOCKERPATHPREFIX}${SCRIPTDIR}/gen-keystore.sh:/tmp/gen-keystore.sh \
    -w /tmp --rm ibmjava bash ./gen-keystore.sh ${IP}
  # Generate keystore
  docker run \
    -v keystore:/tmp/keystore \
    -v ${DOCKERPATHPREFIX}${SCRIPTDIR}/gen-keystore.sh:/tmp/gen-keystore.sh \
    -w /tmp --rm ibmjava bash ./gen-keystore.sh ${IP}
fi

echo " Downloading platform services (one time)"

docker-compose -f $SCRIPTDIR/platformservices.yml pull
rc=$?
if [ $rc -ne 0 ]
then
  echo "Trouble pulling required platform images, we need to sort that first"
  exit 1
fi

docker-compose pull
rc=$?
if [ $rc -ne 0 ]
then
  echo "Trouble pulling core images, we need to sort that first"
  exit 1
fi

echo "

If you haven't already, start the platform services with:
 ./go-platform-services.sh start

Once platform services have started successfully: 
  * Launch core game services using: 
    ./go-run.sh start all 

  * If you are editing/updating core game services, rebuild and launch using:
    ./go-run.sh rebuild all

The game will be running at https://${IP}/ when you're all done."
