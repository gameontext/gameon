#!/bin/bash

# This will help start/stop Game On services using docker-compose.
# Note the example docker-compose overlay file to facilitate single
# service iterative development while running other/unmodified core
# game services locally.
#
# `eval $(docker/go-run.sh env)` will set aliases to more easily invoke
# this script's actions from the command line.
#

SCRIPTDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $SCRIPTDIR/docker-functions

GO_DEPLOYMENT=docker
get_gameontext_hostip

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
  else
    echo "Starting containers (detached) [$PROJECTS]"
    echo "View logs: "
    echo "    ./docker/go-run.sh logs $PROJECTS"
  fi
  echo
  echo "Launching containers will take some time as dependencies are coordinated."
  echo "*****"
  echo

  wrap_compose up -d $@
  if [ $NOLOGS -eq 0 ]; then
    sleep 3
    wrap_compose logs --tail="5" -f $@
  fi
}

down_rm() {
  echo "Stopping containers [$PROJECTS]"
  wrap_compose stop $@
  echo
  echo "*****"
  echo "Cleaning up containers [$PROJECTS]"
  wrap_compose rm $@
}

refresh() {
  ## Refresh base images (betas)
  echo "Pulling fresh images [$PROJECTS]"
  wrap_compose build --pull $PROJECTS
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
      wrap_compose build ${project}

      cd ..
    elif [ "${project}" == "webapp" ]; then
      build_webapp
    else
      echo "${project} is not a gradle project. No other build instructions. Re-building docker image"
      wrap_compose build ${project}
    fi
  done
}

setup() {
  docker_versions
  ensure_keystore

  SOURCE=$SCRIPTDIR/gameon.env
  TARGET=$SCRIPTDIR/gameon.${DOCKER_MACHINE_NAME}env
  if [ ! -f $TARGET ]; then
    cat $SOURCE | sed -e 's/FRONT_END_\\(.*\\)127.0.0.1\\(.*\\)/FRONT_END_\\1'${HTTPS_HOSTPORT}'\\2/g' > $TARGET
    ok "Created gameon.${DOCKER_MACHINE_NAME}env to contain environment variable overrides"
    echo "This file will use the docker host ip address ($GAMEON_HOST), but will re-map ports for forwarding from the VM."
  fi

  # Attempt to pull all images except for util, which is built locally
  local LIST="$PROJECTS $COREPROJECTS"
  wrap_compose pull ${LIST//util/}
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
    status
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
    wrap_compose build $PROJECTS
  ;;
  down)
    wrap_compose stop $PROJECTS
    platform_down
  ;;
  env)
    echo "alias go-compose='${COMPOSE}';"
    echo "alias go-run='${SCRIPTDIR}/go-run.sh';"
    # global setup | up | down
    echo "alias go-admin='${GO_DIR}/go-admin.sh'"
  ;;
  logs)
    wrap_compose logs -f $PROJECTS
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
    wrap_compose kill -s HUP proxy
  ;;
  reset_kafka)
    reset_kafka
  ;;
  restart)
    down_rm $PROJECTS
    up_log $PROJECTS
  ;;
  rm)
    wrap_compose rm $PROJECTS
  ;;
  setup)
    setup
  ;;
  reset)
    wrap_compose stop $PROJECTS
    platform_down
    wrap_docker volume rm -f keystore
  ;;
  start)
    up_log $PROJECTS
  ;;
  status)
    wrap_compose ps
  ;;
  stop)
    wrap_compose stop $PROJECTS
  ;;
  up)
    NOLOGS=1
    platform_up
    up_log $PROJECTS
    echo "To test for readiness: http://${HTTP_HOSTPORT}/site_alive"
    echo 'To wait for readiness: ./docker/go-run.sh wait'
    echo 'To watch progress :popcorn: ./docker/go-run.sh logs'
    echo 'To type less: eval $(./docker/go-run.sh env)'
  ;;
  wait)
    echo "Waiting until http://${HTTP_HOSTPORT}/site_alive returns OK."
    echo "This may take awhile, as it is starting a number of containers at the same time."
    echo "If you're curious, cancel this, and use './docker/go-run.sh logs' to watch what is happening"

    until $(curl --output /dev/null --silent --head --fail http://${GAMEON_HOST}/site_alive 2>/dev/null)
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
