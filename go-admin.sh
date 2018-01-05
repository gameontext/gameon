#!/bin/bash
#
# Copyright 2017 IBM Corporation
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
BASEDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source ${BASEDIR}/bin/go-common

# Ensure we're executing from project root directory
cd "${BASEDIR}"

#set the action, default to help if none passed.
ACTION="help"
if [ $# -ge 1 ]; then
  ACTION=$1
  shift
fi

GO_DEPLOYMENT=${GO_DEPLOYMENT-docker-compose}

usage() {
  echo "Actions: setup|up|down"
}

case "$ACTION" in
  setup)
    echo "Game On! Setting things up with $GO_DEPLOYMENT"
    if [ "$GO_DEPLOYMENT" = "docker-compose" ]; then
      ./docker/go-run.sh setup
    else
      if [ "$GO_DEPLOYMENT" = "kubernetes" ]; then
        ./kubernetes/go-run.sh setup
      else
        echo "Unknown deployment type $GO_DEPLOYMENT"
      fi
    fi
    echo $GO_DEPLOYMENT > .gameontext
  ;;
  up)
    if ! [ -f .gameontext ] || [ "$GO_DEPLOYMENT" != "$(< .gameontext)" ]; then
      $0 setup
    fi
    echo "Game On! Starting game services with $GO_DEPLOYMENT"
    echo "This may take awhile. Be patient."
    if [ "$GO_DEPLOYMENT" = "docker-compose" ]; then
      echo "For logs and other actions, use scripts in the docker/ directory"
      ./docker/go-run.sh up
    else
      if [ "$GO_DEPLOYMENT" = "kubernetes" ]; then
        ./kubernetes/go-run.sh up
      else
        echo "Unknown deployment type $GO_DEPLOYMENT"
      fi
    fi
  ;;
  down)
    echo "Game On! Stopping game services with $GO_DEPLOYMENT"
    if [ "$GO_DEPLOYMENT" = "docker-compose" ]; then
      ./docker/go-run.sh down
    else
      if [ "$GO_DEPLOYMENT" = "kubernetes" ]; then
        ./kubernetes/go-run.sh down 
      else
        echo "Unknown deployment type $GO_DEPLOYMENT"
      fi
    fi
  ;;
  *)
    usage
  ;;
esac
