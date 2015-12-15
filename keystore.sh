#!/bin/sh
rm -f keystore/key.jks
rm -f keystore/public.crt
rm -f keystore/truststore.jks
mkdir -p keystore
keytool -genkey -alias default -storepass testOnlyKeystore -keypass testOnlyKeystore -keystore keystore/key.jks -keyalg RSA -sigalg SHA1withRSA -validity 365 -dname "CN=localcert,OU=unknown,O=unknown,L=unknown,ST=unknown,C=CA" 
keytool -export -alias default -storepass testOnlyKeystore -keypass testOnlyKeystore -keystore keystore/key.jks -file keystore/public.crt
keytool -import -noprompt -alias default -storepass truststore -keypass truststore -keystore keystore/truststore.jks -file keystore/public.crt
rm -f keystore/public.crt
