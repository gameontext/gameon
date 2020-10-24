#!/bin/bash

echo "** Create key and trust stores **"

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

if [ $# -lt 2 ]; then
  echo "Must specify two parameters:
  1) the source directory (can be read-only, contains cert.pem)
  2) the target directory (must be read-write)

  An optional third parameter can specify additional environment checks.
  Known values:
    local: verify certificate/keystore volume contents for local dev

  keystore.jks and truststore.jks will be created in the specified target directory.
  The truststore should be specified as the JVM default using:
    -Djavax.net.ssl.trustStore=${target_dir}/truststore.jks \
    -Djavax.net.ssl.trustStorePassword=gameontext-trust
"

  exit 1
fi

src_dir=$1
target_dir=$2
orig_dir=${pwd}
local_dev=1

if [ ! -f ${src_dir}/cert.pem ]; then
  echo "Missing certificate: ${src_dir}/cert.pem"
  exit 1
fi

if [ "$3" == "local" ]; then
  touch ${target_dir}/.local.volume

  if [ ! -f ${src_dir}/server.pem ]; then
    echo "Missing server certificate: ${src_dir}/server.pem"
    exit 1
  fi
  if [ ! -f ${src_dir}/private.pem ]; then
    echo "Missing key certificate: ${src_dir}/private.pem"
    exit 1
  fi
  if [ ! -f ${src_dir}/ltpa.keys ]; then
    echo "Missing ltpa.keys: ${src_dir}/ltpa.keys"
    exit 1
  fi
elif [ -f ${target_dir}/.local.volume ]; then
  echo "Using keystores created in a shared volume"
  exit 0
fi

inspect() {
  if [ -f ${target_dir}/.local.volume ] ; then
    echo "inspect $1 $2"
    keytool -list \
        -keystore $1 -storepass $2 -storetype PKCS12
    echo ""
  fi
}
inspect_jks() {
  if [ -f ${target_dir}/.local.volume ] ; then
    echo "inspect $1 $2"
    keytool -list \
        -keystore $1 -storepass $2
    echo ""
  fi
}

cp ${src_dir}/*.pem ${target_dir}
cp ${src_dir}/*.keys ${target_dir}

echo "Building keystore/truststore from cert.pem"
echo " # cd ${target_dir}"
cd ${target_dir}

echo " # converting pem to pkcs12"
openssl pkcs12 -passin pass:keystore -passout pass:keystore -export -out cert.pkcs12 -in cert.pem

echo " # importing cert.pkcs12 to key.pkcs12"
keytool -v -importkeystore -alias 1 -noprompt \
        -srckeystore cert.pkcs12 -srckeypass keystore -srcstorepass keystore -srcstoretype PKCS12 -srcalias 1 \
        -destkeystore key.pkcs12 -destkeypass gameontext-keys -deststorepass gameontext-keys -deststoretype PKCS12 -destalias default


echo " # importing jvm truststore to server truststore"
cacerts=$JAVA_HOME/jre/lib/security/cacerts
if [ -e $JAVA_HOME/lib/security/cacerts ]; then
  cacerts=$JAVA_HOME/lib/security/cacerts
fi

keytool -importkeystore \
        -srckeystore ${cacerts} -srcstorepass changeit \
        -destkeystore truststore.jks -deststorepass gameontext-trust

echo " # Add cert.pm to truststore"
keytool -import -alias gameontext -v -noprompt \
  -trustcacerts  \
  -file cert.pem \
  -keystore truststore.jks -storepass gameontext-trust

cd ${orig_dir}

if [ -f ${target_dir}/.local.volume ]; then
  echo "** Contents of ${target_dir}"
  ls -al ${target_dir}

  echo "** Keystore"
  inspect ${target_dir}/key.pkcs12 gameontext-keys
fi

