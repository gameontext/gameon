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

#set the action, default to help if none passed.
if [ $# -lt 1 ]
then
  ACTION=help
else
  ACTION=$1
  shift
fi

#for when running from scripts..
if [ $# -gt 0 ] && [ $1 == "--nologs" ]
then
  NOLOGS=1
  shift
else
  NOLOGS=0
fi

ALLPROJECTS="auth map mediator player proxy room webapp"
if [ $# -lt 1 ]
then
  PROJECTS=$ALLPROJECTS
elif [ $1 == "all" ]
then
  PROJECTS=$ALLPROJECTS
else
  PROJECTS=$@
fi

OVERRIDE=
if [ -f docker-compose.override.yml ]
then
  OVERRIDE='-f docker-compose.override.yml'
fi

#configure docker compose command
COMPOSE="docker-compose -f docker-compose.yml ${OVERRIDE} -f platformservices.yml"
if [ "$(uname)" != "Darwin" ] && [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]
then
    COMPOSE="sudo ${COMPOSE}"
fi

#setup docker ip.
NAME=${DOCKER_MACHINE_NAME-empty}
IP=127.0.0.1
if [ "$NAME" != "empty" ] && [ "$NAME" != "" ]
then
  IP=$(docker-machine ip $NAME)
fi

up_log() {
    if [ $NOLOGS -eq 0 ]
    then
      echo "${COMPOSE} up -d $PROJECTS, logs will continue in the foreground."
    else
      echo "${COMPOSE} up -d $PROJECTS, logs are viewable using go-run.sh logs $PROJECTS"
    fi
    ${COMPOSE} up -d $@
    if [ $NOLOGS -eq 0 ]
    then
      ${COMPOSE} logs --tail="5" -f $@
    fi
}

down_rm() {
    echo "docker-compose stop $@"
    ${COMPOSE} stop $@
    ${COMPOSE} rm $@
}

gradle_build() {
  for project in $@
  do
    echo -n "Evaluating ${project} for gradle build. :: "
    if [ -d "${project}" ] && [ -e "${project}/build.gradle" ]
    then
      echo "Building project ${project} with gradle"
      cd "$project"
      ../gradlew build
      rc=$?
      cd ..
      if [ $rc != 0 ]
      then
        echo Gradle build failed. Please investigate, GameOn is unlikely to work until the issue is resolved.
        exit 1
      fi
    elif [ "${project}" == "webapp" ]
    then
      echo "Docker-based build for webapp using `docker-compose run webapp-build` "
      docker-compose run --rm webapp-build
    else
      echo "No need to gradle build project ${project}"
    fi
  done
}

usage() {
  echo "Actions: start|stop|restart|build|rebuild|rm|logs"
  echo "Use optional arguments to select one or more specific image"
}

case "$ACTION" in
  logs)
    ${COMPOSE} logs -f $PROJECTS
  ;;
  start|up)
    up_log $PROJECTS
  ;;
  stop|down)
    echo "docker-compose stop $PROJECTS"
    ${COMPOSE} stop $PROJECTS
  ;;
  restart)
    down_rm $PROJECTS
    up_log $PROJECTS
  ;;
  build)
    down_rm $PROJECTS
    ${COMPOSE} build $PROJECTS
  ;;
  rebuild)
    down_rm $PROJECTS
    echo "rebuilding $PROJECTS"
    gradle_build $PROJECTS
    if [ $? != 0 ]
    then
      echo Gradle build of $PROJECTS failed.. please examine logs and retry as appropriate.
      exit 3
    fi
    echo "docker-compose build --pull $PROJECTS"
    ${COMPOSE} build --pull $PROJECTS
    if [ $? != 0 ]
    then
      echo Docker build of $PROJECTS failed.. please examine logs and retry as appropriate.
      exit 2
    fi
    up_log $PROJECTS
  ;;
  rm)
    echo "docker-compose rm $PROJECTS"
    ${COMPOSE} rm $PROJECTS
  ;;
  *)
  usage
  ;;
esac
