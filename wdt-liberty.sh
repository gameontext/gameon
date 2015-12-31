#!/bin/sh

WLP_INSTALL_DIR=$1

# Update an existing liberty installation to contain all of the features necessary.
if ! [ -d "$WLP_INSTALL_DIR" ] || ! [ -x "${WLP_INSTALL_DIR}/bin/installUtility" ]
then
    read -e -p "Entry path to Liberty installation: " dir
    # Reinvoke with the path, so we can try again.
    exec $0 $dir
fi

echo "Updating $WLP_INSTALL_DIR"
TOP=$PWD

for SUBDIR in *
do
  if [ -d "${SUBDIR}" ] && [ -d "${SUBDIR}/${SUBDIR}-wlpcfg" ]
  then
      export WLP_USER_DIR=${SUBDIR}/${SUBDIR}-wlpcfg
      cd ${WLP_USER_DIR}/servers
      for SERVER in *
      do
        echo "Checking features in ${SERVER}"
        ${WLP_INSTALL_DIR}/bin/installUtility install ${SERVER}/server.xml
      done

      cd $TOP
  fi
done
