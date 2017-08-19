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

PLATFORM="kafka redis couchdb controller gateway registry a8admin"
if [ "$1" == "start" ]; then
    ensure_keystore

    if [ "$2" != "--force" ]; then
      echo "Testing for running platform.. "

      FOUND=$(${DOCKER_CMD} ps --format="{{.Names}}")
      OK=1
      for svc in $PLATFORM; do
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

    echo "Starting platform services ${PLATFORM}"

    # Scrap any that were left running from before
    ${COMPOSE} kill ${PLATFORM}
    ${COMPOSE} rm -f ${PLATFORM}

    # Start new ones
    ${COMPOSE} up -d ${PLATFORM}
elif [ "$1" == "stop" ]; then
    echo "Stopping control plane services..."
    ${COMPOSE} kill  ${PLATFORM}
    ${COMPOSE} rm -f ${PLATFORM}
    docker volume rm -q $(docker volume list -f 'dangling=true' -q)
else
    echo "usage: $0 start|stop (--force)"
    exit 1
fi
