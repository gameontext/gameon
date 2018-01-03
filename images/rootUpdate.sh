#!/bin/bash

#
# Travis builds: Update the submodule version in the root repository
# after a successful build.
#

echo TRAVIS_BRANCH=$TRAVIS_BRANCH
echo SUBMODULE=${SUBMODULE}
echo SUBMODULE_COMMIT=${SUBMODULE_COMMIT}

if [ -z ${SUBMODULE} ]; then
  echo SUBMODULE not set
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
  openssl aes-256-cbc -K $ENCRYPTED_KEY -iv $ENCRYPTED_IV -in images/go-travis.id_rsa.enc -out images/go-travis.id_rsa -d

  chmod 600 images/go-travis.id_rsa
  eval `ssh-agent -s`
  ssh-add images/go-travis.id_rsa
fi

git config user.email "${GITHUB_EMAIL}"
git config user.name "Travis CI"

# Get the last good submodule
git submodule init ${SUBMODULE}
git submodule update --init --remote --no-fetch ${SUBMODULE}

cd ${SUBMODULE}
if [ -n ${SUBMODULE_COMMIT} ]; then
  echo "Checking out submodule ${SUBMODULE} commit ${SUBMODULE_COMMIT}"
fi
git checkout ${SUBMODULE_COMMIT}

cd ..
if git diff --quiet; then
    echo "No changes to the output on this push; exiting."
    exit 0
fi

# Now that we're all set up, we can push the altered submodule to master
git commit -a -m ":arrow_up: Updating to latest version of ${SUBMODULE}..." || true

echo git push $SSH_REPO $TRAVIS_BRANCH
#git push $SSH_REPO master || true
