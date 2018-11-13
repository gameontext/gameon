#!/bin/bash -x
## This is run from inside containers that require couchdb and/or cloudant

# Environment variables look like this:
# COUCHDB_SERVICE_URL=http://couchdb:5984
# COUCHDB_HOST_AND_PORT=couchdb:5984
# COUCHDB_USER=mapUser
# COUCHDB_PASSWORD=myCouchDBSecret
# GAMEON_MODE=development

# Ensure trailing slash
COUCHDB_SERVICE_URL=${COUCHDB_SERVICE_URL%%/}/
AUTH_URL=${COUCHDB_SERVICE_URL/\/\//\/\/$COUCHDB_USER:$COUCHDB_PASSWORD@}
COUCHDB_NODE=_node/nonode@nohost/

activeUrl=${COUCHDB_SERVICE_URL}

LIMIT=0
if [ -n "$1" ]; then
  LIMIT=$1
fi
check_limit() {
  ((count++))
  if [ $LIMIT -gt 0 ]; then
    if [ $count -gt ${LIMIT} ]; then
      echo "Exceeded ${LIMIT} attempts"
      exit 1
    fi
  fi
}

ensure_exists() {
  local uri=$1
  local url=${activeUrl}$uri
  shift

  count=0
  local result=0
  while [ $result -ne 200 ]; do
    check_limit
    result=$(curl -s -o /dev/null -w "%{http_code}" --fail -X GET $url)
    echo "****${count}: curl -X GET $uri  ==>  $result "

    case "$result" in
      200)
        continue
      ;;
      401) #retry with Auth URL (required after admin user added)
        activeUrl=${AUTH_URL}
        url=${activeUrl}$uri
      ;;
      404)
        echo "-- curl $@ -X PUT $uri  ==>  $result"
        curl -s $@ -X PUT $url
      ;;
      409) # conflict. Wait and try again
        sleep 10
      ;;
      *)
        echo "unknown error with $uri";
        curl -s --fail -X GET $url
        exit 1
      ;;
    esac
  done
}

assert_exists() {
  local uri=$1
  local url=${activeUrl}$uri

  local result=$(curl -s -o /dev/null -w "%{http_code}" --fail -X GET $url)
  echo "**** curl -X GET $uri  ==>  $result "
  if [ $result -ne 200 ]; then
    curl -s --fail -X GET $url
    exit 1
  fi
}

# RC=7 means the host isn't there yet. Let's do some re-trying until it
# does start / is ready
RC=7
count=0
while [ $RC -eq 7 ]; do
  check_limit
  echo "**${count}: Testing connection to ${COUCHDB_SERVICE_URL}"
  curl -s --fail -X GET ${COUCHDB_SERVICE_URL}
  RC=$?

  if [ $RC -eq 7 ]; then
    sleep 15
  fi
done

if [ "${GAMEON_MODE}" == "development" ]
then
  echo "Initializing Cloudant"

  # LOCAL DEVELOPMENT!
  # We do not want to ruin the cloudant admin party, but our code is written to expect
  # that creds are required, so we should make sure the required user/password exist
  # We also have to ensure (with Cloudant 2.x) that we're using the right node URL

  ensure_exists _users
  ensure_exists _replicator
  ensure_exists ${COUCHDB_NODE}_config/admins/${COUCHDB_USER} -d \"${COUCHDB_PASSWORD}\"
fi

echo "ok!"
