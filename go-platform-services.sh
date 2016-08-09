#!/bin/bash
#
# Copyright 2016 IBM Corporation
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

#set -x

SCRIPTDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

if [ "$1" == "start" ]; then

    if [ "$2" != "--force" ]; then
      echo "Testing for running platform.. "
   
      EXPECTED="controller couchdb elasticsearch gateway kafka kibana logstash registry" 
      FOUND=`docker ps --format="{{.Names}}"`
      OK=1
      for svc in $EXPECTED; do
        echo -n "Checking for Service $svc"
        echo $FOUND | grep -qs $svc
        if [ $? == 0 ]; then
          echo -e "\t..found."
        else
          echo -e "\t..not found."
          OK=0
        fi
      done

      if [ $OK == 1 ]; then
        echo "Running platform found. No need to start platform"
        exit 0
      fi
    fi

    echo "Starting platform services (kafka, ELK stack, couchdb, a8 controller,registry,gateway)"
    
    docker-compose -f $SCRIPTDIR/platformservices.yml up -d
    
    echo "Waiting 1 minute for the platform to initialize.."
    sleep 60
    echo "Platform considered initialized, proceeding.."
    
    NAME=${DOCKER_MACHINE_NAME-empty}
    IP=127.0.0.1
    if [ "$NAME" == "empty" ]; then
      echo "DOCKER_MACHINE_NAME is not set. If you don't use docker-machine, you can ignore this, or export DOCKER_MACHINE_NAME=''"
    elif [ -n $NAME ]; then
      IP=$(docker-machine ip $NAME)
      rc=$?
      if [ $rc != 0 ] || [ -z ${DOCKER_HOST} ]
      then
        echo "Is your docker host running? Did you start docker-machine, e.g. 
  docker-machine start default
  eval \$(docker-machine env default)"
        exit 1 
      fi
    fi

    AR=$(docker inspect -f '{{.NetworkSettings.IPAddress}}' registry ):8080
    AC=$IP:31200
    KA=$(docker inspect -f '{{.NetworkSettings.IPAddress}}' kafka ):9092
    echo "Setting up a new tenant named 'local' via controller $AC"
    read -d '' tenant << EOF
{
    "credentials": {
        "kafka": {
            "brokers": ["${KA}"],
            "sasl": false
        },
        "registry": {
            "url": "http://${AR}",
            "token": "local"
        }
    }
}
EOF
    echo $tenant | curl -H "Content-Type: application/json" -H "Authorization: local" -d @- "http://${AC}/v1/tenants"
elif [ "$1" == "stop" ]; then
    echo "Stopping control plane services..."
    docker-compose -f $SCRIPTDIR/platformservices.yml kill
    docker-compose -f $SCRIPTDIR/platformservices.yml rm -f
else
    echo "usage: $0 start|stop (--force)"
    exit 1
fi
