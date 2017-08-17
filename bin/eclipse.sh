#!/bin/sh
## Initialize all sub-modules that have gradle present with Eclipse metadata

dir=$(dirname $0)
pushd "$dir"/..  > /dev/null
echo "Finding Java projects in $PWD"

for SUBDIR in *
do
  if [ -d "${SUBDIR}" ] && [ -e "${SUBDIR}/build.gradle" ]
  then
    pushd $SUBDIR > /dev/null
    ../gradlew cleanEclipse eclipse
    popd ..  > /dev/null
  fi
done

popd  > /dev/null
