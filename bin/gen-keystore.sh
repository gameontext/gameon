#!/bin/bash

echo "** Populating keystore volume **"

# Generate keystores in ./keystore for a given IP
if [ -z ${JAVA_HOME} ]
then
  echo "JAVA_HOME is not set. Please set and re-run this script."
  exit 1
fi

echo "Checking for keytool..."
keytool -help > /dev/null 2>&1
if [ $? != 0 ]
then
  echo "Error: keytool is missing from the path, please correct this, then retry"
  exit 1
fi

echo "Checking for openssl..."
openssl version > /dev/null 2>&1
if [ $? != 0 ]
then
  echo "Error: openssl is missing from the path, please correct this, then retry"
  exit 1
fi

if [ ! -f cert.pem ]; then
  echo "Missing certificate"
  exit 1
fi
if [ ! -f server.pem ]; then
  echo "Missing server certificate"
  exit 1
fi
if [ ! -f private.pem ]; then
  echo "Missing key certificate"
  exit 1
fi
if [ ! -f ltpa.keys ]; then
  echo "Missing ltpa.keys"
  exit 1
fi

cp *.pem keystore
cp *.keys keystore


echo "Building keystore/truststore from cert.pem"

echo "-converting pem to pkcs12"
openssl pkcs12 -passin pass:keystore -passout pass:keystore -export -out cert.pkcs12 -in cert.pem

echo "-importing pem to keystore/truststore.jks"
keytool -import -v -trustcacerts -alias default -file cert.pem -storepass truststore -keypass keystore -noprompt -keystore keystore/truststore.jks

echo "-creating dummy key.jks"
keytool -genkey -storepass testOnlyKeystore -keypass wefwef -keyalg RSA -alias endeca -keystore keystore/key.jks -dname CN=rsssl,OU=unknown,O=unknown,L=unknown,ST=unknown,C=CA

echo "-emptying key.jks"
keytool -delete -storepass testOnlyKeystore -alias endeca -keystore keystore/key.jks

echo "-importing pkcs12 to key.jks"
keytool -v -importkeystore -srcalias 1 -alias 1 -destalias default \
  -noprompt -srcstorepass keystore -deststorepass testOnlyKeystore \
  -srckeypass keystore -destkeypass testOnlyKeystore \
  -srckeystore cert.pkcs12 -srcstoretype PKCS12 -destkeystore keystore/key.jks -deststoretype JKS

# Adding google certs to truststore
echo | openssl s_client -showcerts -servername *.googleapis.com \
  -connect www.googleapis.com:443 </dev/null 2>&1 | sed -ne '/BEGIN\ CERTIFICATE/,/END\ CERTIFICATE/ p' > googleca.pem
 
keytool -import -v -trustcacerts -alias googleca -file googleca.pem -storepass truststore -keypass keystore -noprompt -keystore keystore/truststore.jks 

curl https://secure.globalsign.net/cacert/Root-R2.crt > globalsign-r2.crt
keytool -import -v -trustcacerts -alias globalsign-r2 -file globalsign-r2.crt -storepass truststore -keypass keystore -noprompt -keystore keystore/truststore.jks

