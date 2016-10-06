#!/bin/bash

# Generate keystores in ./keystore for a given IP

if (( $# != 1))
then
  echo "Usage: ./gen-keystore.sh <IP>"
  exit 1
fi

IP=$1

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

echo "Building pem extractor"
mkdir -p setup-utils

#HAProxy will need the private key in PEM format, but keytool
# only allows us to save private keys in pkcs12, thankfully java
# is pretty easy to use to create us a tool to export private keys
# in PEM format.. so we'll just inline a small bit here to let us
# do that later.
# (Yes, you can do this with openssl, but we don't have that as a prereq)
cat > setup-utils/PemExporter.java << 'EOT'
  import java.util.*;
  import java.io.*;
  import java.security.*;

  public class PemExporter
  {
      private File keystoreFile;
      private String keyStoreType;
      private char[] keyStorePassword;
      private char[] keyPassword;
      private String alias;
      private File exportedFile;
      private static final byte[] CRLF = new byte[] {'\r', '\n'};

      public void export() throws Exception {
          KeyStore keystore = KeyStore.getInstance(keyStoreType);
          keystore.load(new FileInputStream(keystoreFile), keyStorePassword);
          Key key = keystore.getKey(alias, keyPassword);
          String encoded = Base64.getMimeEncoder(64,CRLF).encodeToString(key.getEncoded());
          FileWriter fw = new FileWriter(exportedFile);
          fw.write("-----BEGIN PRIVATE KEY-----\n");
          fw.write(encoded);
          fw.write("\n");
          fw.write("-----END PRIVATE KEY-----");
          fw.close();
      }

      public static void main(String args[]) throws Exception {
          PemExporter export = new PemExporter();
          export.keystoreFile = new File(args[0]);
          export.keyStoreType = args[1];
          export.keyStorePassword = args[2].toCharArray();
          export.alias = args[3];
          export.keyPassword = args[4].toCharArray();
          export.exportedFile = new File(args[5]);
          export.export();
      }
  }
EOT
cd setup-utils
javac PemExporter.java
if [ $? != 0 ]
then
  echo "Error: failed to compile the certificate exported"
  exit 1
fi
cd ..

echo "Generating key stores using ${IP}"

#create a ca cert we'll import into all our trust stores..
keytool -genkeypair \
  -alias gameonca \
  -keypass gameonca \
  -storepass gameonca \
  -keystore keystore/cakey.jks \
  -keyalg RSA \
  -keysize 2048 \
  -dname "CN=GameOnLocalDevCA, OU=The Amazing GameOn Certificate Authority, O=The Ficticious GameOn Company, L=Earth, ST=Happy, C=CA" \
  -ext KeyUsage="keyCertSign" \
  -ext BasicConstraints:"critical=ca:true" \
  -validity 9999
#export the ca cert so we can add it to the trust stores
keytool -exportcert \
  -alias gameonca \
  -keypass gameonca \
  -storepass gameonca \
  -keystore keystore/cakey.jks \
  -file keystore/gameonca.crt \
  -rfc
#create the keypair we plan to use for our ssl/jwt signing
keytool -genkeypair \
  -alias gameonappkey \
  -keypass testOnlyKeystore \
  -storepass testOnlyKeystore \
  -keystore keystore/key.jks \
  -keyalg RSA \
  -sigalg SHA1withRSA \
  -dname "CN=${IP},OU=GameOn Application,O=The Ficticious GameOn Company,L=Earth,ST=Happy,C=CA" \
  -validity 365
#create the signing request for the app key
keytool -certreq \
  -alias gameonappkey \
  -keypass testOnlyKeystore \
  -storepass testOnlyKeystore \
  -keystore keystore/key.jks \
  -file keystore/appsignreq.csr
#sign the cert with the ca
keytool -gencert \
  -alias gameonca \
  -keypass gameonca \
  -storepass gameonca \
  -keystore keystore/cakey.jks \
  -infile keystore/appsignreq.csr \
  -outfile keystore/app.cer
#import the ca cert
keytool -importcert \
  -alias gameonca \
  -storepass testOnlyKeystore \
  -keypass testOnlyKeystore \
  -keystore keystore/key.jks \
  -noprompt \
  -file keystore/gameonca.crt
#import the signed cert
keytool -importcert \
  -alias gameonappkey \
  -storepass testOnlyKeystore \
  -keypass testOnlyKeystore \
  -keystore keystore/key.jks \
  -noprompt \
  -file keystore/app.cer
#change the alias of the signed cert
keytool -changealias \
  -alias gameonappkey \
  -destalias default \
  -storepass testOnlyKeystore \
  -keypass testOnlyKeystore \
  -keystore keystore/key.jks
#export the signed cert in pem format for proxy to use
keytool -exportcert \
  -alias default \
  -storepass testOnlyKeystore \
  -keypass testOnlyKeystore \
  -keystore keystore/key.jks \
  -file keystore/app.pem \
  -rfc
#export the private key in pem format for proxy to use
$JAVA_HOME/bin/java -cp setup-utils PemExporter\
  keystore/key.jks \
  JCEKS \
  testOnlyKeystore \
  default \
  testOnlyKeystore \
  keystore/private.pem
#concat the public and private key for haproxy
cat keystore/app.pem keystore/private.pem > keystore/proxy.pem
#add the cacert to the truststore
keytool -importcert \
  -alias gameonca \
  -storepass truststore \
  -keypass truststore \
  -keystore keystore/truststore.jks \
  -noprompt \
  -trustcacerts \
  -file keystore/gameonca.crt
#add all jvm cacerts to the truststore.
keytool -importkeystore \
  -srckeystore $JAVA_HOME/lib/security/cacerts \
  -destkeystore keystore/truststore.jks \
  -srcstorepass changeit \
  -deststorepass truststore
#clean up the public cert..
rm -f keystore/public.crt
