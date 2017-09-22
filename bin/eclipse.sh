#!/bin/sh
## Initialize all sub-modules that have gradle present with Eclipse metadata

dir=$(dirname $0)
pushd "$dir"/..
echo "Finding Java projects in $PWD"

for SUBDIR in *
do
  if [ -d "${SUBDIR}" ] && [ -e "${SUBDIR}/build.gradle" ]
  then
    pushd $SUBDIR
    ./gradlew cleanEclipse eclipse
    popd
  fi
done

popd
