#!/bin/bash

ACTION=$1
CONTAINER_NAME=go-admin-$USER

function get_status {
  PS=$(bx ic ps -a --format '{{.Names}}\t{{.ID}}\t{{.Status}}' | awk '$1 ~ '"/${CONTAINER_NAME}/"' { print }')
  CONTAINER=$( echo $PS | cut -d " " -f 2 )
  STATUS=$( echo $PS | cut -d " " -f 3 )
  echo $PS
}

function stop_clean {
  case "$STATUS" in
    Running)
      bx ic stop $CONTAINER
      while [ "Running" == "${STATUS}" ]; do
        sleep 2
        get_status
      done
      bx ic rm $CONTAINER
    ;;
    Shutdown)
      bx ic rm $CONTAINER
    ;;
    *)
    ;;
  esac
}

case "$ACTION" in
  build)
    bx ic build -t registry.ng.bluemix.net/gameon/gameon-admin .
  ;;

  start)
    echo "Checking for a container named ${CONTAINER_NAME}"
    get_status
    if [ -z "$CONTAINER" ]; then
      VOLUME=$(bx ic volumes | grep prim)
      IMAGE=$(bx ic images | awk '$1 ~ /gameon-admin/ { print $3 }')

      # Configure our link to etcd based on shared volume with secret
      if [ -z "$ETCD_SECRET" ]; then
        read -p "ETCD_SECRET not configured, enter it now: " secret

        if [ -z "${secret}" ]; then
          echo "A secret must be specified"
          exit
        fi
        ETCD_SECRET=${secret}
      fi

      bx ic run --name "${CONTAINER_NAME}" -e "ETCD_SECRET=${ETCD_SECRET}" \
                --volume ${VOLUME}:/data --rm ${IMAGE}

      get_status
      while [ "Building" == "${STATUS}" ]; do
        sleep 2
        get_status
      done
    else
      read -p "A containe already exists, clean it up? (y or N) " stop_now
      if [ "y" == "$stop_now" ]; then
        stop_clean
      fi
    fi
  ;;

  run)
    echo "Checking for a running container named ${CONTAINER_NAME}"
    get_status
    if [ -z "$CONTAINER" ] || [ "Running" != "${STATUS}" ]; then
      echo "Start container first"
      exit 0
    fi


    bx ic exec -it ${CONTAINER} /bin/bash -l
  ;;

  stop)
    echo "Checking for a running container named ${CONTAINER_NAME}"
    get_status
    stop_clean
  ;;

  status)
    get_status
  ;;

  *)
    echo "go-admin build | start | run | stop "
  ;;
esac
