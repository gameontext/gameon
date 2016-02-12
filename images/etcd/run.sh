#!/bin/sh

if [ -z ${ETCD_NAME+x} ]
then
  echo "Unable to determine name! Set in ENV: -e 'ETCD_NAME=name'"
  exit 1
fi

echo "ETCD_NAME is ${ETCD_NAME}"

if [ -z ${ETCD_LISTEN_CLIENT_URLS+x} ]; then
  export ETCD_LISTEN_CLIENT_URLS="http://0.0.0.0:4001,http://0.0.0.0:2379"
  export ETCD_ADVERTISE_CLIENT_URLS="http://${ETCD_NAME}:4001,http://${ETCD_NAME}:2379,http://${HOSTNAME}:4001,http://${HOSTNAME}:2379"
  echo "Using ETCD_LISTEN_CLIENT_URLS ($ETCD_LISTEN_CLIENT_URLS)"  
else
  echo "Detected ETCD_LISTEN_CLIENT_URLS value of $ETCD_LISTEN_CLIENT_URLS"
fi

# /data is loaded as an NFS mount, and etcd doesn't play nicely with NFS mounts.
# To avoid this, copy the backup from the NFS mount into a local folder, and then
# use the local folder as the data dir
cd /data
mkdir /curData
cp -r * /curData
cd -

ETCD_CMD="/usr/bin/etcd -data-dir=/curData -force-new-cluster"

echo -e "Running '$ETCD_CMD'\nBEGIN ETCD OUTPUT\n"

exec $ETCD_CMD

