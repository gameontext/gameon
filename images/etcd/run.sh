#!/bin/sh

if [ -z ${ETCD_NAME+x} ]
then
  echo "Unable to determine name! Set in ENV: -e 'ETCD_NAME=name'"
  exit 1
fi

if [ -z ${ETCD_LISTEN_CLIENT_URLS+x} ]; then
  export ETCD_LISTEN_CLIENT_URLS="http://0.0.0.0:4001,http://0.0.0.0:2379"
  export ETCD_ADVERTISE_CLIENT_URLS="http://${HOSTNAME}:4001,http://${HOSTNAME}:2379"
  echo "Using ETCD_LISTEN_CLIENT_URLS ($ETCD_LISTEN_CLIENT_URLS)"  
else
  echo "Detected ETCD_LISTEN_CLIENT_URLS value of $ETCD_LISTEN_CLIENT_URLS"
fi

#if [ -z ${ETCD_LISTEN_PEER_URLS+x} ]; then
#  export ETCD_LISTEN_PEER_URLS="http://0.0.0.0:7001,http://0.0.0.0:2380"
#  echo "Using ETCD_LISTEN_PEER_URLS ($ETCD_LISTEN_PEER_URLS)"
#else
#  echo "Detected ETCD_LISTEN_PEER_URLS value of $ETCD_LISTEN_PEER_URLS"
#fi


ETCD_CMD="/usr/bin/etcd -data-dir=/data -wal-dir=/data.wal $*"

echo -e "Running '$ETCD_CMD'\nBEGIN ETCD OUTPUT\n"

exec $ETCD_CMD

