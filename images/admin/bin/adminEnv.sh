#!/bin/bash

source /data/primordial/etcd.env.sh

export TAIL=$(ps ef | grep "tail -f /dev/null" | grep -v grep | cut -d " " -f 1)
function stopTail {
  kill $TAIL
}
export -f stopTail
alias exit='stopTail; exit'

if [ "$ETCDCTL_ENDPOINT" != "" ]; then
  echo Setting up etcd...
  echo "** Testing etcd is accessible"
  etcdctl --debug ls
  RC=$?

  while [ $RC -ne 0 ]; do
    sleep 15
    # recheck condition
    echo "** Re-testing etcd connection"
    etcdctl --debug ls
    RC=$?
  done
  echo "etcdctl returned sucessfully"

  export A8_REGISTRY_URL=$(etcdctl get /amalgam8/registryUrl)
  if [ -n "$A8_REGISTRY_URL" ]; then
    export A8_CONTROLLER_URL=$(etcdctl get /amalgam8/controllerUrl)
    export A8_CONTROLLER_POLL=$(etcdctl get /amalgam8/controllerPoll)

    JWT=$(etcdctl get /amalgam8/jwt)
    export A8_REGISTRY_TOKEN=$JWT
    export A8_CONTROLLER_TOKEN=$JWT
  fi
fi
