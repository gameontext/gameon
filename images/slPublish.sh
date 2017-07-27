#!/bin/bash

#
# This script is only intended to run in the IBM DevOps Services Pipeline Environment.
#
echo Setting up Docker...
mkdir dockercfg ; cd dockercfg
echo -e $KEY > key.pem
echo -e $CA_CERT > ca.pem
echo -e $CERT > cert.pem
echo Key `echo $KEY | md5sum`
echo Ca Cert `echo $CA_CERT | md5sum`
echo Cert `echo $CERT | md5sum`
cd ..

echo Obtaining docker.
curl https://download.docker.com/linux/static/stable/x86_64/docker-17.06.0-ce.tgz | tar xvz

cd $TARGET_DIR

../docker/docker build -t $TARGET_CONTAINER -f Dockerfile .
if [ $? != 0 ]
then
  echo "Docker build failed, will NOT attempt to stop/rm/start-new-container."
  exit -2
else
  echo Attempting to remove old containers.
  ../docker/docker stop -t 0 $TARGET_CONTAINER || true
  ../docker/docker rm $TARGET_CONTAINER || true
  echo Starting new container.
  ../docker/docker run -d -p 9089:9080 -p 9449:9443 --restart=always --link etcd -e LICENSE=accept -e ETCDCTL_ENDPOINT=http://etcd:4001 --name=$TARGET_CONTAINER $TARGET_CONTAINER
  if [ $? != 0 ]
  then
    echo "Docker run failed.. it's too late.. the damage is done already."
    exit -3
  fi
fi

cd ..
rm -rf dockercfg
