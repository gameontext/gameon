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
source $SCRIPTDIR/go-common

# Ensure we're executing from project root directory
cd "${SCRIPTDIR}"/..

if [ "$1" == "start" ]; then

    if [ "$2" != "--force" ]; then
      echo "Testing for running platform.. "

      EXPECTED="controller couchdb elasticsearch gateway kafka kibana logstash registry redis"
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

    echo "Starting platform services (kafka, ELK stack, couchdb, a8-controller, a8-registry, redis, gateway)"

    docker-compose -f $SCRIPTDIR/platformservices.yml up -d

    echo "Waiting 1 minute for the platform to initialize.."
    sleep 60
    echo "Platform considered initialized, proceeding.."

    REGISTRY_URL=http://$IP:31300
    CONTROLLER_URL=http://$IP:31200

    # Wait for controller route to set up
    echo "Waiting for controller route to set up"
    attempt=0
    while true; do
        code=$(curl -w "%{http_code}" "${CONTROLLER_URL}/health" -o /dev/null)
        if [ "$code" = "200" ]; then
            echo "Controller route is set to '$CONTROLLER_URL'"
            break
        fi

        attempt=$((attempt + 1))
        if [ "$attempt" -gt 10 ]; then
            echo "Timeout waiting for controller route: /health returned HTTP ${code}"
            echo "Deploying the controlplane has failed"
            exit 1
        fi
        sleep 10s
    done

    # Wait for registry route to set up
    echo "Waiting for registry route to set up"
    attempt=0
    while true; do
        code=$(curl -w "%{http_code}" "${REGISTRY_URL}/uptime" -o /dev/null)
        if [ "$code" = "200" ]; then
            echo "Registry route is set to '$REGISTRY_URL'"
            break
        fi

        attempt=$((attempt + 1))
        if [ "$attempt" -gt 10 ]; then
            echo "Timeout waiting for registry route: /uptime returned HTTP ${code}"
            echo "Deploying the controlplane has failed"
            exit 1
        fi
        sleep 10s
    done

elif [ "$1" == "stop" ]; then
    echo "Stopping control plane services..."
    docker-compose -f $SCRIPTDIR/platformservices.yml kill
    docker-compose -f $SCRIPTDIR/platformservices.yml rm -f
else
    echo "usage: $0 start|stop (--force)"
    exit 1
fi
