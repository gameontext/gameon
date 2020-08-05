#!/bin/bash

targetDir=$1
if [ -z "$targetDir" ]; then
  echo "Usage: specify targetDir for generated certificate"
  exit 1
fi
shift

hostName=$1
if [ -z "$hostName" ]; then
  echo "Usage: specify Hostname or IP address for certificate as argument"
  exit 1
fi

if [ -f ${targetDir}/.gameontext.onlycert.pem ]; then
  subject=$(openssl x509 -in ${targetDir}/.gameontext.onlycert.pem -text -noout | grep Subject:)
  cert_hostname=$(echo ${subject} | sed -e 's/ //g' -e 's/.*CN=\([^,/]*\).*/\1/')
  if [ "$cert_hostname" != "$hostName" ]; then
    echo "Existing certificate hostname (${cert_hostname}) does not match the requested hostname (${hostName}). Regenerating certificate"
    rm ${targetDir}/.gameontext.cert.pem
  fi
fi

ALT=
j=1
for x in $@; do
  if [[ $x =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    echo Not adding $x as DNS
  else
    echo Adding $x as DNS
    ALT="$ALT"$'\n'"DNS.${j} = ${x}"
    ((j++))
  fi
done
if [[ $hostName =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
  echo Adding $hostName as IP
  ALT="$ALT"$'\n'"IP.${j} = ${hostName}"
fi

mkdir -p ${targetDir}/.gameontext.openssl > /dev/null 2>&1

# Create certificate (for signing JWTs)
if [ ! -f ${targetDir}/.gameontext.cert.pem ]; then
  echo " - Creating certificate for ${hostName} "

  #Generate CA Key And Cert
  echo " - Generating CA & Cert"
  SUBJECT="/CN=gameontext.org/OU=GameOn Development CA/O=The Ficticious GameOn CA Company/L=Earth/ST=Happy/C=CA"
  openssl genrsa -out ${targetDir}/.gameontext.openssl/server_rootCA.key 4096
  openssl req -x509 -new -nodes -sha256 -days 3650 \
    -key ${targetDir}/.gameontext.openssl/server_rootCA.key \
    -out ${targetDir}/.gameontext.openssl/server_rootCA.pem \
    -subj "${SUBJECT}"

  #Create CSR config
cat <<EOT > ${targetDir}/.gameontext.openssl/rootCSR.cnf
[req]
default_bits = 4096
prompt = no
default_md = sha256
distinguished_name = dn

[dn]
C=CA
ST=Happy
L=Earth
O=The Ficticious GameOn Company
OU=GameOn Application
CN = ${hostName}

EOT

cat <<EOT > ${targetDir}/.gameontext.openssl/v3.ext
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = ${hostName}${ALT}

EOT

  echo " - Create Server Key & CSR"
  #Create Server Key, with CSR
  openssl req -new -sha256 -nodes \
    -out ${targetDir}/.gameontext.openssl/server.csr -newkey rsa:4096 \
    -keyout ${targetDir}/.gameontext.onlykey.pem -config <( cat ${targetDir}/.gameontext.openssl/rootCSR.cnf )

  echo " - Sign CSR"
  #Sign CSR with CA
  openssl x509 -req \
    -in ${targetDir}/.gameontext.openssl/server.csr \
    -CA ${targetDir}/.gameontext.openssl/server_rootCA.pem \
    -CAkey ${targetDir}/.gameontext.openssl/server_rootCA.key -CAcreateserial \
    -out ${targetDir}/.gameontext.onlycert.pem -days 3650 -sha256 \
    -extfile ${targetDir}/.gameontext.openssl/v3.ext

  #Append Server Cert & Key into single file for haproxy.
  cat ${targetDir}/.gameontext.onlycert.pem ${targetDir}/.gameontext.onlykey.pem > ${targetDir}/.gameontext.cert.pem
fi
