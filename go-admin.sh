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
source bin/go-common

#set the action, default to help if none passed.
if [ $# -lt 1 ]
then
  ACTION=help
else
  ACTION=$1
  shift
fi

GO_DEPLOYMENT=${GO_DEPLOYMENT-docker-compose}

usage() {
  echo "Actions: setup|up|down"
  echo "Use optional arguments to select one or more specific image"
}

case "$ACTION" in
  setup)
    echo "Game On! Setting things up with $GO_DEPLOYMENT"
    if [ "$GO_DEPLOYMENT" = "docker-compose" ]
    then
      ./docker/go-setup.sh
    else
      echo "else k8s"
    fi
    echo $GO_DEPLOYMENT > .gameontext
  ;;
  up)
    if ! [ -f .gameontext ] || [ "$GO_DEPLOYMENT" != "$(< .gameontext)" ]
    then
      $0 setup
    fi
    echo "Game On! Starting game services with $GO_DEPLOYMENT"
    echo "This may take awhile. Be patient."
    if [ "$GO_DEPLOYMENT" = "docker-compose" ]
    then
      echo "For logs and other actions, use scripts in the docker/ directory"
      ./docker/go-run.sh up
    else
      echo "else k8s"
    fi
  ;;
  down)
    echo "Game On! Stopping game services with $GO_DEPLOYMENT"
    if [ "$GO_DEPLOYMENT" = "docker-compose" ]
    then
      ./docker/go-run.sh down
    else
      echo "else k8s"
    fi
  ;;
  *)
    usage
  ;;
esac
