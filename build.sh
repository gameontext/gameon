#!/bin/sh

# If the keystore directory doesn't exist, then we should generate
# the keystores we need for local signed JWTs to work
if [ ! -d keystore ]
then
  echo "Generating key stores"
  rm -f keystore/key.jks
  rm -f keystore/public.crt
  rm -f keystore/truststore.jks
  mkdir -p keystore
  keytool -genkey -alias default -storepass testOnlyKeystore -keypass testOnlyKeystore -keystore keystore/key.jks -keyalg RSA -sigalg SHA1withRSA -validity 365 -dname "CN=localcert,OU=unknown,O=unknown,L=unknown,ST=unknown,C=CA"
  keytool -export -alias default -storepass testOnlyKeystore -keypass testOnlyKeystore -keystore keystore/key.jks -file keystore/public.crt
  keytool -import -noprompt -alias default -storepass truststore -keypass truststore -keystore keystore/truststore.jks -file keystore/public.crt
  rm -f keystore/public.crt
fi

# Support environments with docker-machine
# For base linux users, 127.0.0.1 is fine, but w/ docker-machine we need to
# use the host ip instead. So we'll generate an over-ridden env file that
# will get passed/copied properly into the target servers
name=${DOCKER_MACHINE_NAME-empty}
if [ "$name" == "empty" ]
then
  echo "DOCKER_MACHINE_NAME is not set. To avoid warning messages, you might set this to ''."
elif [ -n $name ]
then
  if [ ! -f gameon.${name}env ]
  then
      IP=$(docker-machine ip $name)
    echo "Creating new environment file gameon.${name}env to contain environment variable overrides.
This file will use the docker host ip address ($IP). 
When the docker containers are up, use https://$IP/ to connect to the game."
    sed -e "s#127.\0.\0\.1#${IP}#g" gameon.env > gameon.${name}env
  fi
fi

for SUBDIR in *
do
  if [ -d "${SUBDIR}" ] && [ -e "${SUBDIR}/build.gradle" ]
  then
    cd $SUBDIR
    ../gradlew build
    cd ..
  fi
done
