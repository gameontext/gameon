#!/bin/sh

#
# Travis builds: Used by submodule builds to build and publish images to dockerhub
#
# environment variables:
#
#  TRAVIS_BRANCH
#  TRAVIS_COMMIT
#  TRAVIS_PULL_REQUEST
#  DOCKER_USERNAME
#  DOCKER_PASSWORD
#  DOCKER_REPO
#  DOCKER_IMAGE
#

COMMIT="${TRAVIS_COMMIT::8}"
IMAGE="${DOCKER_REPO}/${DOCKER_IMAGE}"
BUILD_TAG="${IMAGE}:${TRAVIS_BRANCH}-${TRAVIS_BUILD_NUMBER}"
LATEST_TAG="${IMAGE}:latest"

echo "Creating docker image for ${TRAVIS_COMMIT} on branch ${TRAVIS_BRANCH}"
docker build \
      --label "gameontext.commit=${TRAVIS_COMMIT}"  \
      --label "gameontext.build=${BUILD_TAG}"  \
     -t ${BUILD_TAG} ${DOCKER_BUILDDIR}
echo "Build complete ${DOCKER_IMAGE}"

if [ "$TRAVIS_BRANCH" == "master" ]; then
  echo "Tagging with  ${LATEST_TAG}"
  docker tag ${BUILD_TAG} ${LATEST_TAG}

  echo "Publishing image"
  docker login -u="${DOCKER_USERNAME}" -p="${DOCKER_PASSWORD}"
  docker push ${IMAGE}
  docker logout
  echo "Push complete"
else
  echo "Not master branch, skipping docker publish"
fi
