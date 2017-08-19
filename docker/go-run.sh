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

ALLPROJECTS="proxy auth map mediator player room webapp"
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
  verify_amalgam8

  if [ $NOLOGS -eq 0 ]
  then
    echo "Starting containers [$PROJECTS], logs will continue in the foreground."
    echo "Start command: "
    echo "    ${COMPOSE} up -d $PROJECTS"
  else
    echo "Starting containers [$PROJECTS], logs will be viewable using: "
    echo "    ./docker/go-run.sh logs $PROJECTS"
    echo "Start command: "
    echo "    ${COMPOSE} up -d $PROJECTS"
  fi

  echo
  echo "Launching containers will take some time, as dependencies are coordinated."
  echo
  ${COMPOSE} up -d $@
  if [ $NOLOGS -eq 0 ]
  then
    ${COMPOSE} logs --tail="5" -f $@
  fi
}

down_rm() {
  echo "Stopping containers [$PROJECTS]"
  echo "    ${COMPOSE} stop $@"
  ${COMPOSE} stop $@
  echo "Cleaning up containers [$PROJECTS]"
  echo "    ${COMPOSE} rm $@"
  ${COMPOSE} rm $@
}

re_pull() {
  ## Refresh base images (betas)
  echo "Pulling fresh images [$PROJECTS]"
  echo "   ${COMPOSE}  build --pull $PROJECTS"
  ${COMPOSE} build --pull $PROJECTS
  if [ $? != 0 ]
  then
    echo Docker build of $PROJECTS failed.. please examine logs and retry as appropriate.
    exit 2
  fi
}

rebuild() {
  echo "Building projects [$PROJECTS]"
  for project in $@
  do
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
      echo "Building docker image for ${project}"
      ${COMPOSE} build ${project}

      cd ..
    elif [ "${project}" == "webapp" ]
    then
      build_webapp
    else
      echo "${project} is not a gradle project. No other build instructions. Re-building docker image"
      ${COMPOSE} build ${project}
    fi
  done
}

usage() {
  echo "Actions: start|stop|restart|wait|build|rebuild|rebuild_only|rm|logs|reset_kafka|env"
  echo "Use optional arguments to select one or more specific image"
}

case "$ACTION" in
  logs)
    ${COMPOSE} logs -f $PROJECTS
  ;;
  env)
    echo "export COMPOSE=\"${COMPOSE}\""
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
  reset_kafka)
    echo "Stop kafka and dependent services"
    ${COMPOSE} stop kafka ${PROJECTS}
    ${COMPOSE} kill kafka ${PROJECTS}
    ${COMPOSE} rm -f kafka ${PROJECTS}
    echo "Resetting kafka takes some time (quiescing, making sure things are dead and that there are no zombies)"
    echo "Sleep 30"
    sleep 30
    echo "Start Kafka"
    ${COMPOSE} up -d kafka
    echo "Sleep 60"
    sleep 60
    ${COMPOSE} logs --tail="5" kafka
    echo "Rebuild projects"
    ${COMPOSE} build  ${PROJECTS}
    ${COMPOSE} up -d  ${PROJECTS}
    ${COMPOSE} logs --tail="5" -f  ${PROJECTS}
  ;;
  rebuild_only)
    rebuild $PROJECTS
  ;;
  rebuild)
    down_rm $PROJECTS
    re_pull $PROJECTS
    rebuild $PROJECTS
    up_log $PROJECTS
  ;;
  rm)
    echo "${COMPOSE} rm $PROJECTS"
    ${COMPOSE} rm $PROJECTS
  ;;
  wait)
    echo "Waiting until http://${HTTP_HOSTPORT}/site_alive returns OK."
    echo "This may take awhile, as it is starting a number of containers at the same time."
    echo "If you're curious, cancel this, and use './docker/go-run.sh logs' to watch what is happening"

    until $(curl --output /dev/null --silent --head --fail http://${IP}/site_alive 2>/dev/null)
    do
      printf '.'
      sleep 5s
    done
    echo ""
    echo "Game On! You're ready to play: https://${HTTPS_HOSTPORT}/"
  ;;
  *)
  usage
  ;;
esac
