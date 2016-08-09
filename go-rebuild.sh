#!/bin/bash
PROJECTS=$@
ALLPROJECTS="auth map mediator player proxy room webapp"
if [ "$PROJECTS" = "all" ]
then
  PROJECTS=$ALLPROJECTS
fi

echo Stopping container $PROJECTS
docker-compose -f docker-compose.yml -f ./platformservices.yml stop $PROJECTS

for project in $PROJECTS
do
  echo "Evaluating ${project} for gradle build."
  if [ -d "${project}" ] && [ -e "${project}/build.gradle" ]
  then
    echo "Building project ${project} with gradle"
    cd "$project"
    ../gradlew build
    rc=$?
    cd ..
    if [ $rc != 0 ]
    then
      echo Gradle build failed. Please investigate, GameOn is unlikely to work until the issue is resolved.
      exit 1
    fi
  else
    echo "No need to gradle build project ${project}"
  fi
done

echo Removing container $PROJECTS
docker-compose -f docker-compose.yml -f ./platformservices.yml rm -f $PROJECTS

echo Rebuilding container $PROJECTS
docker-compose -f docker-compose.yml -f ./platformservices.yml build $PROJECTS

echo Relaunching container $PROJECTS
docker-compose -f docker-compose.yml -f ./platformservices.yml up -d $PROJECTS

#setup a8 env vars.. 
NAME=${DOCKER_MACHINE_NAME-empty}
IP=127.0.0.1
if [ $NAME != "empty" ]
then
  IP=$(docker-machine ip $NAME)
fi
echo Setting default routes where needed
export A8_CONTROLLER_URL=http://${IP}:31200
export A8_REGISTRY_URL=http://${IP}:31300
for service in auth map mediator players proxy ; do curl -sS -X PUT ${A8_CONTROLLER_URL}/v1/versions/${service} -d '{"default" : "v1"}' -H "Authorization: local" -H "Content-Type: application/json"; done
