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
  if [ $rc != 0 ] || [ -z ${DOCKER_HOST} ]
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
  sed -e "s#127.\0.\0\.1#${IP}#g" gameon.env > gameon.${NAME}env
fi

# If the keystore directory doesn't exist, then we should generate
# the keystores we need for local signed JWTs to work
if [ ! -d keystore ]
then
  echo "Checking for keytool..."
  keytool -help > /dev/null 2>&1
  if [ $? != 0 ]
  then
     echo "Error: keytool is missing from the path, please correct this, then retry"
	 exit 1
  fi
  echo "Generating key stores using ${IP}"
  mkdir -p keystore
  keytool -genkey -alias default -storepass testOnlyKeystore -keypass testOnlyKeystore -keystore keystore/key.jks -keyalg RSA -sigalg SHA1withRSA -validity 365 -dname "CN=${IP},OU=unknown,O=unknown,L=unknown,ST=unknown,C=CA"
  keytool -export -alias default -storepass testOnlyKeystore -keypass testOnlyKeystore -keystore keystore/key.jks -file keystore/public.crt
  keytool -import -noprompt -trustcacerts -alias default -storepass truststore -keypass truststore -keystore keystore/truststore.jks -file keystore/public.crt
  rm -f keystore/public.crt
fi

#check for selinux by looking for chcon and sestatus..
#needed for fedora else the keystore dirs cannot be mapped in by
#docker-compose volume mapping
if [ -x "$(type -P chcon)" ] && [ -x "$(type -P sestatus)" ]
then
  echo ""
  echo "SELinux detected, adding svirt_sandbox_file_t to keystore dir"
  chcon -Rt svirt_sandbox_file_t ./keystore
fi

SCRIPTDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

echo " Downloading platform services (one time)"

docker-compose -f $SCRIPTDIR/platformservices.yml pull
rc=$?
if [ $rc != 0 ]
then
  echo "Trouble pulling required platform images, we need to sort that first"
  exit 1
fi 

docker-compose pull
rc=$?
if [ $rc != 0 ]
then
  echo "Trouble pulling core images, we need to sort that first"
  exit 1
fi 

echo "

If you haven't already, start the platform services with:
 ./go-platform-services.sh start

If all of that went well, rebuild the and launch the game-on docker containers with:
 ./go-run.sh all

The game will be running at https://${IP}/ when you're all done."
