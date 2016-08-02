#!/bin/sh

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

if [ $# -lt 1 ]
then
  ACTION=help
else
  ACTION=$1
  shift
fi

if [ "$(uname)" == "Darwin" ]
then
    COMPOSE="docker-compose"
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]
then
    COMPOSE="sudo docker-compose"
else
    COMPOSE="docker-compose"
fi

up_log() {
    echo "${COMPOSE} up -d $@, logs will continue in the foreground."
    ${COMPOSE} up -d $@
    ${COMPOSE} logs --tail="5" -f $@
}

down_rm() {
    echo "docker-compose stop $@"
    ${COMPOSE} stop $@
    ${COMPOSE} rm $@
}

case "$ACTION" in
  logs)
    ${COMPOSE} logs -f $@
  ;;
  start|up)
    up_log $@
  ;;
  stop|down)
    echo "docker-compose stop $@"
    ${COMPOSE} stop $@
  ;;
  restart)
    down_rm $@
    up_log $@
  ;;
  rebuild)
    down_rm $@
    echo "docker-compose build --pull $@"
    ${COMPOSE} build --pull
    up_log $@
  ;;
  rm)
    echo "docker-compose rm $@"
    ${COMPOSE} rm $@
  ;; 
  *)
    echo "Actions: start|stop|restart|rebuild|rm|logs"
    echo "Use optional arguments to select one or more specific image"
  ;;
esac
