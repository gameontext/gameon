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

if [ -z "${DOCKER_MACHINE_NAME+xxx}" ]
then
  echo "DOCKER_MACHINE_NAME is not set. To avoid warning messages, you might set this to ''."
elif [ -n $DOCKER_MACHINE_NAME ]
then
  if [ ! -f gameon.${DOCKER_MACHINE_NAME}env ]
  then
      IP=$(docker-machine ip $DOCKER_MACHINE_NAME)
      echo $IP
      sed -e "s#127.\0.\0\.1#${IP}#g" gameon.env > gameon.${DOCKER_MACHINE_NAME}env
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
