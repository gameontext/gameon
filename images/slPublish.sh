#!/bin/bash

#
# This script is only intended to run in the IBM DevOps Services Pipeline Environment.
#
echo Setting up Docker in $PWD

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

DIR=${TARGET_DIR-empty}
if [ "$DIR" != "empty" ] && [ "$TARGET_DIR" != "" ]; then
  cd $TARGET_DIR
  DOCKER="../docker/docker"
else
  DOCKER="docker/docker"
fi

FILE=${Dockerfile-empty}
if [ "$DIR" == "empty" ] || [ "$Dockerfile" == "" ]; then
  Dockerfile="Dockerfile"
fi

echo Docker path is ${DOCKER} from ${PWD}

${DOCKER} build -t $TARGET_CONTAINER -f ${Dockerfile} .
if [ $? != 0 ]
then
  echo "Docker build failed, will NOT attempt to stop/rm/start-new-container."
  exit -2
else
  echo Build successful.
  #echo Attempting to remove old containers.
  #${DOCKER} stop -t 0 $TARGET_CONTAINER || true
  #${DOCKER} rm $TARGET_CONTAINER || true
  #echo Starting new container.

  #if [ -n $HTTP ]; then
  #  HTTP="-p $HTTP:9080"
  #fi
  #if [ -n $HTTPS ]; then
  #  HTTPS="-p $HTTPS:9443"
  #fi

  #${DOCKER} run -d $HTTP $HTTPS $PORT_MAPPINGS --restart=always --link etcd -e LICENSE=accept -e ETCDCTL_ENDPOINT=http://etcd:4001 --name=$TARGET_CONTAINER $TARGET_CONTAINER
  #if [ $? != 0 ]
  #then
  #  echo "Docker run failed.. it's too late.. the damage is done already."
  #  exit -3
  #fi
fi

if [ -n $TARGET_DIR ]; then
  cd ..
fi

rm -rf dockercfg
rm -rf docker
