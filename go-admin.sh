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

usage() {
  echo "Actions: choose|setup|up|down|env"
}

# get deployment type (go_common)
get_deployment

case "$ACTION" in
  choose)
    if [[ ! $1 =~  [12] ]]; then
      echo "Which do you want to use?
  [1] Docker Compose
  [2] Kubernetes"
    fi
    answer=$1
    while [ "$answer" != 1 ] && [ "$answer" != 2 ]; do
      read -p '[1 or 2]: ' answer
    done
    if [ $answer == 2 ]; then
      GO_DEPLOYMENT="kubernetes"
    else
      GO_DEPLOYMENT="docker"
    fi
    ok "Selected $GO_DEPLOYMENT"
    echo $GO_DEPLOYMENT > .gameontext
  ;;
  setup)
    echo "Game On! Setting things up with $GO_DEPLOYMENT (Use '$0 choose' to change)"
    if [[ $GO_DEPLOYMENT =~ (docker|kubernetes) ]]; then
      ./${GO_DEPLOYMENT}/go-run.sh setup
    else
      echo "Unknown deployment type $GO_DEPLOYMENT"
    fi
  ;;
  up)
    if ! [ -f .gameontext ] || [ "$GO_DEPLOYMENT" != "$(< .gameontext)" ]; then
      $0 setup
    fi
    echo "Game On! Starting game services with $GO_DEPLOYMENT"
    echo "This may take awhile. Be patient."
    if [[ $GO_DEPLOYMENT =~ (docker|kubernetes) ]]; then
      echo "For other actions, use scripts in the ${GO_DEPLOYMENT}/ directory"
      ./${GO_DEPLOYMENT}/go-run.sh up
    else
      echo "Unknown deployment type $GO_DEPLOYMENT"
    fi
  ;;
  down)
    echo "Game On! Stopping game services with $GO_DEPLOYMENT"
    if [[ $GO_DEPLOYMENT =~ (docker|kubernetes) ]]; then
      ./${GO_DEPLOYMENT}/go-run.sh down
    else
      echo "Unknown deployment type $GO_DEPLOYMENT"
    fi
  ;;
  env)
    if [[ $GO_DEPLOYMENT =~ (docker|kubernetes) ]]; then
      ./${GO_DEPLOYMENT}/go-run.sh env
    else
      echo "Unknown deployment type $GO_DEPLOYMENT"
    fi
  ;;
  *)
    usage
  ;;
esac
