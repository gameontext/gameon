#!/bin/bash

#
# Travis builds: Used by submodule builds to kick off a build of the
# root repository  (eventual target is rootUpdate.sh)
# This script should only run  if this is not a Pull request
#

echo TRAVIS_BRANCH=${TRAVIS_BRANCH}
echo TRAVIS_COMMIT=${TRAVIS_COMMIT}
echo SUBMODULE=${SUBMODULE}

if [ "$TRAVIS_PULL_REQUEST" = "false" ]; then
  echo "No submodule updates for pull requests"
  exit
fi

if [ -z ${SUBMODULE} ]; then
  echo "SUBMODULE not set"
  exit
fi

# If the root repository has the same branch as the child repository,
# this will update the commit level of the submodule in that branch.
if git ls-remote --exit-code --heads git@github.com:gameontext/gameon.git ${TRAVIS_BRANCH}
  body='{
  "request": {
    "branch":"${TRAVIS_BRANCH}",
    "config": {
      "env": {
        "SUBMODULE": "${SUBMODULE}",
        "SUBMODULE_COMMIT": "${TRAVIS_COMMIT}"
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
