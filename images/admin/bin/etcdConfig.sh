#!/bin/bash

# Configure our link to etcd based on shared volume with secret
if [ ! -z "$ETCD_SECRET" ] && [ -d /data ] ; then
  echo "Configuring for secure etcd"
  . /data/primordial/setup.etcd.sh /data/primordial $ETCD_SECRET
else
  echo "ETCD_SECRET not configured, and/or primordial mount is missing"
fi

# prevent container from exiting
tail -f /dev/null
