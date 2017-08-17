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
source $SCRIPTDIR/go-common

# Ensure we're executing from project root directory
cd "${SCRIPTDIR}"/..

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

up_log() {
  ensure_keystore
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
    echo "${COMPOSE} stop $@"
    ${COMPOSE} stop $@
    ${COMPOSE} rm $@
}

re_pull() {
  ## Refresh base images (betas)
  echo "${COMPOSE}  build --pull $PROJECTS"
  ${COMPOSE} build --pull $PROJECTS
  if [ $? != 0 ]
  then
    echo Docker build of $PROJECTS failed.. please examine logs and retry as appropriate.
    exit 2
  fi
}

gradle_build() {
  for project in $@
  do
    echo -n "Building ${project} :: "
    if [ -d "${project}" ] && [ -e "${project}/build.gradle" ]
    then
      echo "Building project ${project} with gradle"

      cd "$project"
      ./gradlew build
      rc=$?
      if [ $rc != 0 ]
      then
        echo Gradle build failed. Please investigate, Game On! is unlikely to work until the issue is resolved.
        exit 1
      fi

      # Build Docker image
      ${COMPOSE} build ${project}

      cd ..
    elif [ "${project}" == "webapp" ]
    then
      echo "Docker-based build for webapp using ${COMPOSE} run webapp-build"
      build_webapp
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
    echo "${COMPOSE}  stop $PROJECTS"
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
  rebuild_only)
    echo "rebuilding $PROJECTS"
    gradle_build $PROJECTS
  ;;
  rebuild)
    down_rm $PROJECTS
    echo "rebuilding $PROJECTS"
    re_pull
    gradle_build $PROJECTS
    up_log $PROJECTS
  ;;
  rm)
    echo "${COMPOSE}  rm $PROJECTS"
    ${COMPOSE} rm $PROJECTS
  ;;
  wait)
    echo "Waiting until http://${IP}/site_alive returns OK."
    echo "This may take awhile, as it is starting a number of containers at the same time."
    echo "If you're curious, cancel this, and use './docker/go-run.sh logs' to watch what is happening"

    until $(curl --output /dev/null --silent --head --fail http://${IP}/site_alive)
    do
      printf '.'
      sleep 5
    done
    echo ""
    echo "Game On! You're ready to play: https://${IP}/"
  ;;
  *)
  usage
  ;;
esac
