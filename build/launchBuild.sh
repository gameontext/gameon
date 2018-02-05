#!/bin/bash

#
# Travis builds: Used by submodule builds to kick off a build of the
# root repository  (eventual target is rootUpdate.sh)
#
# This script should only run when code is pushed (not for PRs, not for
# cron builds or for API-driven builds)
#

echo TRAVIS_EVENT_TYPE=${TRAVIS_EVENT_TYPE}
echo TRAVIS_BRANCH=${TRAVIS_BRANCH}
echo TRAVIS_COMMIT=${TRAVIS_COMMIT}
echo TRAVIS_BUILD_NUMBER=${TRAVIS_BUILD_NUMBER}
echo SUBMODULE=${SUBMODULE}

case "${TRAVIS_EVENT_TYPE}" in
  "push")
    echo "Launch submodule build for push"
    ;;
  *)
    echo "No submodule build for ${TRAVIS_EVENT_TYPE} builds"
    exit 0
    ;;
esac

if [ -z ${SUBMODULE} ]; then
  echo "SUBMODULE not set"
  exit
fi

# If the root repository has the same branch as the child repository,
# this will update the commit level of the submodule in that branch.
if git ls-remote --exit-code --heads https://github.com/gameontext/gameon.git ${TRAVIS_BRANCH}
then
  body='{
  "request": {
    "branch":"'${TRAVIS_BRANCH}'",
    "message":":up: Update from '${SUBMODULE}'#'${TRAVIS_BUILD_NUMBER}'",
    "config": {
      "env": {
        "SUBMODULE": "'${SUBMODULE}'",
        "SUBMODULE_COMMIT": "'${TRAVIS_COMMIT}'",
        "SUBMODULE_BUILD": "'${TRAVIS_BUILD_NUMBER}'"
      }
    }
  }}'

  curl -s -X POST \
     -H "Content-Type: application/json" \
     -H "Accept: application/json" \
     -H "Travis-API-Version: 3" \
     -H "Authorization: token ${TRAVIS_TOKEN}" \
     -d "$body" \
     https://api.travis-ci.org/repo/gameontext%2Fgameon/requests
else
  echo "${TRAVIS_BRANCH} does not exist in gameontext/gameon"
fi
