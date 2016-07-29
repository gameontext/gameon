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
fi
shift

case "$ACTION" in
  start|up)
    echo "docker-compose up -d $@"
    docker-compose up -d $@
    docker-compose logs --tail="5" -f $@
  ;;
  stop|down)
    echo "docker-compose stop $@"
    docker-compose stop $@
  ;;
  restart)
    echo "docker-compose stop $@"
    docker-compose stop $@
    docker-compose rm $@
    echo "docker-compose up -d $@"
    docker-compose up -d $@
    docker-compose logs --tail="5" -f $@
  ;;
  rebuild)
    echo "docker-compose stop $@"
    docker-compose stop $@
    docker-compose rm $@
    echo "docker-compose build --pull $@"
    docker-compose build --pull
    echo "docker-compose up -d $@"
    docker-compose up -d $@
    docker-compose logs --tail="5" -f $@
  ;; 

