#!/bin/bash
PROJECTS=$@
ALLPROJECTS="auth map mediator player proxy room webapp"
if [ "$PROJECTS" = "all" ]
then
  PROJECTS=$ALLPROJECTS
fi

echo Stopping container $PROJECTS
sudo docker-compose -f docker-compose.yml -f ./platformservices.yml stop $PROJECTS

for project in "$PROJECTS"
do
  if [ -d "${project}" ] && [ -e "${project}/build.gradle" ]
  then
    cd "$project"
    ../gradlew build
    rc=$?
    cd ..
    if [ $rc != 0 ]
    then
      echo Gradle build failed. Please investigate, GameOn is unlikely to work until the issue is resolved.
      exit 1
    fi
  fi
done

echo Removing container $PROJECTS
sudo docker-compose -f docker-compose.yml -f ./platformservices.yml rm -f $PROJECTS

echo Rebuilding container $PROJECTS
sudo docker-compose -f docker-compose.yml -f ./platformservices.yml build $PROJECTS

echo Relaunching container $PROJECTS
sudo docker-compose -f docker-compose.yml -f ./platformservices.yml up -d $PROJECTS

#setup A8 env vars before using a8ctl..
NAME=${DOCKER_MACHINE_NAME-empty}
IP=127.0.0.1
if [ $NAME != "empty" ]
then
  IP=$(docker-machine ip $NAME)
fi
echo Setting default routes where needed
export A8_CONTROLLER_URL=http://${IP}:31200
export A8_REGISTRY_URL=http://${IP}:31300
for service in `a8ctl route-list | grep UNVERSIONED | cut -d'|' -f 2 ` ; do a8ctl route-set --default v1 $service; done
