#!/bin/bash

#
# Travis builds: Update the submodule version in the root repository
# after a successful build.
# Invoked by .travis.yml
#

echo TRAVIS_EVENT_TYPE=${TRAVIS_EVENT_TYPE}
echo TRAVIS_BRANCH=${TRAVIS_BRANCH}

case "${TRAVIS_EVENT_TYPE}" in
  "api")
    echo "Launch submodule build for api trigger"
    ;;
  *)
    echo "No submodule build for ${TRAVIS_EVENT_TYPE} builds"
    exit 0
    ;;
esac

echo SUBMODULE=${SUBMODULE}
echo SUBMODULE_COMMIT=${SUBMODULE_COMMIT}
echo SUBMODULE_BUILD=${SUBMODULE_BUILD}

if [ -z ${SUBMODULE} ]; then
  echo "SUBMODULE not set"
  exit
fi

REPO=`git config remote.origin.url`
SSH_REPO=${REPO/https:\/\/github.com\//git@github.com:}

# Get the deploy key by using Travis's stored variables to decrypt deploy_key.enc
if [ -n "$ENCRYPTION_LABEL" ]; then
  ENCRYPTED_KEY_VAR="encrypted_${ENCRYPTION_LABEL}_key"
  ENCRYPTED_IV_VAR="encrypted_${ENCRYPTION_LABEL}_iv"
  ENCRYPTED_KEY=${!ENCRYPTED_KEY_VAR}
  ENCRYPTED_IV=${!ENCRYPTED_IV_VAR}
  openssl aes-256-cbc -K $ENCRYPTED_KEY -iv $ENCRYPTED_IV -in build/go-travis.id_rsa.enc -out build/go-travis.id_rsa -d

  chmod 600 build/go-travis.id_rsa
  eval `ssh-agent -s`
  ssh-add build/go-travis.id_rsa
fi

## Create a fresh clone of this branch in the repo
git clone -b ${TRAVIS_BRANCH} ${SSH_REPO}
cd gameon

# set user info for build automation
git config user.email "${GITHUB_EMAIL}"
git config user.name "Travis CI"

# Initialize the specified submodule
git submodule init ${SUBMODULE}
git submodule update --init --remote --no-fetch ${SUBMODULE}

# Change to the submodule directory, and check out the specified branch
cd ${SUBMODULE}
git checkout ${TRAVIS_BRANCH}

cd ..
echo "-- Git status --"
git status
git diff
if git diff --quiet; then
  echo "-- No changes -- "
  echo "No changes to the output on this push; exiting."
  exit 0
fi

# Now that we're all set up, we can push the altered submodule to master
echo "-- Git commit -- "
git commit -a -m ":arrow_up: Updating to latest version of ${SUBMODULE}..." || true

echo "-- Git push -- "
echo git push origin ${TRAVIS_BRANCH}
git push origin ${TRAVIS_BRANCH} || true
