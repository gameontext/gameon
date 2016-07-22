#!/bin/sh

# Support environments with docker-machine
# For base linux users, 127.0.0.1 is fine, but w/ docker-machine we need to
# use the host ip instead. So we'll generate an over-ridden env file that
# will get passed/copied properly into the target servers
NAME=${DOCKER_MACHINE_NAME-empty}
IP=127.0.0.1
if [ "$NAME" = "empty" ]
then
  echo "DOCKER_MACHINE_NAME is not set. To avoid warning messages, you might set this to ''."
elif [ -n $NAME ]
then
  IP=$(docker-machine ip $NAME)
  if [ ! -f gameon.${NAME}env ]
  then
    echo "Creating new environment file gameon.${NAME}env to contain environment variable overrides.
This file will use the docker host ip address ($IP).
When the docker containers are up, use https://$IP/ to connect to the game."
  fi
  sed -e "s#127.\0.\0\.1#${IP}#g" gameon.env > gameon.${NAME}env
fi

# If the keystore directory doesn't exist, then we should generate
# the keystores we need for local signed JWTs to work
if [ ! -d keystore ]
then
  echo "Generating key stores using ${IP}"
  mkdir -p keystore
  keytool -genkey -alias default -storepass testOnlyKeystore -keypass testOnlyKeystore -keystore keystore/key.jks -keyalg RSA -sigalg SHA1withRSA -validity 365 -dname "CN=${IP},OU=unknown,O=unknown,L=unknown,ST=unknown,C=CA"
  keytool -export -alias default -storepass testOnlyKeystore -keypass testOnlyKeystore -keystore keystore/key.jks -file keystore/public.crt
  keytool -import -noprompt -trustcacerts -alias default -storepass truststore -keypass truststore -keystore keystore/truststore.jks -file keystore/public.crt
  rm -f keystore/public.crt
fi

for SUBDIR in *
do
  if [ -d "${SUBDIR}" ] && [ -e "${SUBDIR}/build.gradle" ]
  then
    cd $SUBDIR
    ../gradlew build
    rc=$?
    cd ..
    if [ $rc != 0 ]
    then
      echo Gradle build failed. Please investigate, GameOn is unlikely to work until the issue is resolved.
      exit 1
    fi
  fi
done

#check for selinux by looking for chcon and sestatus..
#needed for fedora else the keystore dirs cannot be mapped in by
#docker-compose volume mapping
if [ -x "$(type -P chcon)" ] && [ -x "$(type -P sestatus)" ]
then
  echo ""
  echo "SELinux detected, adding svirt_sandbox_file_t to keystore dir"
  chcon -Rt svirt_sandbox_file_t ./keystore
fi

echo "
Make sure you have installed amalgam8 ..
 pip install a8ctl
Now, if you haven't already, start the platform services with:
 ./run-platform-services.sh start
If all of that went well, rebuild the and launch the game-on docker containers with:
 ./rebuild.sh all

The game will be running at https://${IP}/ when you're all done."
