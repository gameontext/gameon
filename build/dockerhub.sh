#!/bin/bash

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

echo $TRAVIS_COMMIT

COMMIT="${TRAVIS_COMMIT::8}"
IMAGE="${DOCKER_REPO}/${DOCKER_IMAGE}"
BUILD_TAG="${IMAGE}:${TRAVIS_BRANCH}-${TRAVIS_BUILD_NUMBER}"
LATEST_TAG="${IMAGE}:latest"

BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"`
URL=${URL-https://gameontext.org}
GITHUB_URL=${GITHUB_URL-https://github.com/${IMAGE}}

echo "Creating docker image for ${TRAVIS_COMMIT} on branch ${TRAVIS_BRANCH}"
docker build \
      --label "org.label-schema.schema-version=1.0" \
      --label "org.label-schema.build-date=${BUILD_DATE}" \
      --label "org.label-schema.vcs-ref=${COMMIT}" \
      --label "org.label-schema.url=${URL}" \
      --label "org.label-schema.vcs-url=${GITHUB_URL}" \
      --label "gameontext.commit=${COMMIT}"  \
      --label "gameontext.build=${BUILD_TAG}"  \
     -t ${BUILD_TAG} ${DOCKER_BUILDDIR}
echo "Build complete ${DOCKER_IMAGE}"

if [ "$TRAVIS_BRANCH" == "main" ]; then
  echo "Tagging with  ${LATEST_TAG}"
  docker tag ${BUILD_TAG} ${LATEST_TAG}

  echo "Publishing image"
  echo "${DOCKER_PASSWORD}" | docker login -u="${DOCKER_USERNAME}" --password-stdin
  docker push ${BUILD_TAG}
  docker push ${LATEST_TAG}
  docker logout
  echo "Push complete"
else
  echo "Not main branch, skipping docker publish"
fi
