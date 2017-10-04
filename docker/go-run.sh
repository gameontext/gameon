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
source $SCRIPTDIR/docker-functions

# Ensure we're executing from project root directory
cd "${SCRIPTDIR}"/..

#set the action, default to help if none passed.
ACTION=help
if [ $# -ge 1 ]; then
  ACTION=$1
  shift
fi

PROJECTS=
NOLOGS=0
#-- Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
  "--nologs")
    NOLOGS=1
  ;;
  all)
    PROJECTS="$COREPROJECTS $PROJECTS"
  ;;
  *) PROJECTS="$1 $PROJECTS"
  ;;
  esac
  shift
done

if [ -z "${PROJECTS}" ]; then
  PROJECTS=$COREPROJECTS
fi

up_log() {
  ensure_keystore

  echo
  echo "*****"
  if [ $NOLOGS -eq 0 ]; then
    echo "Starting containers (detached) [$PROJECTS]"
    echo "Logs will continue in the foreground."
    echo "Start command: "
    echo "    ${COMPOSE} up -d $PROJECTS"
  else
    echo "Starting containers (detached) [$PROJECTS]"
    echo "View logs: "
    echo "    ./docker/go-run.sh logs $PROJECTS"
    echo "Start command: "
    echo "    ${COMPOSE} up -d $PROJECTS"
  fi
  echo
  echo "Launching containers will take some time as dependencies are coordinated."
  echo "*****"
  echo

  ${COMPOSE} up -d $@
  if [ $NOLOGS -eq 0 ]; then
    sleep 3
    ${COMPOSE} logs --tail="5" -f $@
  fi
}

down_rm() {
  echo "Stopping containers [$PROJECTS]"
  echo "    ${COMPOSE} stop $@"
  ${COMPOSE} stop $@
  echo
  echo "*****"
  echo "Cleaning up containers [$PROJECTS]"
  echo "    ${COMPOSE} rm $@"
  ${COMPOSE} rm $@
}

refresh() {
  ## Refresh base images (betas)
  echo "Pulling fresh images [$PROJECTS]"
  echo "   ${COMPOSE}  build --pull $PROJECTS"
  ${COMPOSE} build --pull $PROJECTS
  if [ $? != 0 ]; then
    echo Docker build of $PROJECTS failed.. please examine logs and retry as appropriate.
    exit 2
  fi
}

rebuild() {
  echo "Building projects [$PROJECTS]"
  for project in $@
  do
    echo
    echo "*****"
    if [ -d "${project}" ] && [ -e "${project}/build.gradle" ]; then
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
      ${COMPOSE} build ${project}

      cd ..
    elif [ "${project}" == "webapp" ]; then
      build_webapp
    else
      echo "${project} is not a gradle project. No other build instructions. Re-building docker image"
      ${COMPOSE} build ${project}
    fi
  done
}

setup() {
  docker_versions
  ensure_keystore
  ${COMPOSE} pull
  rc=$?
  if [ $rc -ne 0 ]; then
    echo "Trouble pulling core images, we need to sort that first"
    exit 1
  fi
  rebuild $PROJECTS

  echo "

  Start the Game On! platform:
    ./go-admin.sh up
  OR:
    ./docker/go-run.sh up

  Set up operational aliases:
    eval \$(./docker/go-run.sh env)

  Check for all services being ready:
    https://${HTTP_HOSTPORT}/site_alive

  Wait for all game services to finish starting:
    ./docker/go-run.sh wait
  OR (with alias):
    go-run wait

  If you are editing/updating core game services, rebuild and launch using:
    ./docker/go-run.sh rebuild
  OR (with alias):
    go-run rebuild

  The game will be running at https://${HTTPS_HOSTPORT}/ when you're all done.

  "
}

usage() {
  echo "
  Actions:
    setup

    up
    down
    start
    stop
    restart
    wait

    build
    rebuild
    rebuild_only
    refresh_images
    rm

    logs
    env

    platform_up
    platform_down

    reload_proxy
    reset_kafka

  Use optional arguments to select specific image(s) by name"
}

case "$ACTION" in
  build)
    down_rm $PROJECTS
    ${COMPOSE} build $PROJECTS
  ;;
  down)
    echo "${COMPOSE} stop $PROJECTS"
    ${COMPOSE} stop $PROJECTS
    platform_down
  ;;
  env)
    echo "alias go-compose='${COMPOSE}';"
    echo "alias go-run='${SCRIPTDIR}/go-run.sh';"
    # global setup | up | down
    echo "alias go-admin='${GO_DIR}/go-admin.sh'"
  ;;
  logs)
    ${COMPOSE} logs -f $PROJECTS
  ;;
  platform_up)
    platform_up $@
  ;;
  platform_down)
    platform_down
  ;;
  rebuild)
    down_rm $PROJECTS
    rebuild $PROJECTS
    up_log $PROJECTS
  ;;
  rebuild_only)
    rebuild $PROJECTS
  ;;
  refresh_images)
    refresh $PROJECTS
  ;;
  reload_proxy)
    ${COMPOSE} kill -s HUP proxy
  ;;
  reset_kafka)
    reset_kafka
  ;;
  restart)
    down_rm $PROJECTS
    up_log $PROJECTS
  ;;
  rm)
    echo "${COMPOSE} rm $PROJECTS"
    ${COMPOSE} rm $PROJECTS
  ;;
  setup)
    setup
  ;;
  start)
    up_log $PROJECTS
  ;;
  stop)
    echo "${COMPOSE} stop $PROJECTS"
    ${COMPOSE} stop $PROJECTS
  ;;
  up)
    NOLOGS=1
    platform_up
    up_log $PROJECTS
    echo "To test for readiness: http://${HTTP_HOSTPORT}/site_alive"
    echo 'To wait for readiness: ./docker/go-run.sh wait'
    echo 'To watch progress :popcorn: ./docker/go-run.sh logs'
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
