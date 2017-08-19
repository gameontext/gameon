#!/bin/bash

code=$(curl --silent -w "%{http_code}" "${A8_CONTROLLER_URL}/health" -o /dev/null)
if [ "$code" = "200" ]; then
  echo "Controller route is healthy"
else
  echo "${A8_CONTROLLER_URL}/health returned HTTP ${code}"
  exit 1
fi

code=$(curl --silent -w "%{http_code}" "${A8_REGISTRY_URL}/uptime" -o /dev/null)
if [ "$code" = "200" ]; then
  echo "Registry route is set to '$REGISTRY_URL'"
else
  echo "${A8_REGISTRY_URL}/uptime returned HTTP ${code}"
  exit 1
fi

code=$(curl --silent -w "%{http_code}" "${A8_CONTROLLER_URL}/v1/rules" -o /dev/null)
if [ "$code" = "200" ]; then
  echo "Controller rules are available"
else
  echo "${A8_CONTROLLER_URL}/v1/rules returned HTTP ${code}"
  exit 1
fi

code=$(curl --silent -w "%{http_code}" "${A8_REGISTRY_URL}/api/v1/instances" -o /dev/null)
if [ "$code" = "200" ]; then
  echo "Registry instances are available"
else
  echo "${A8_REGISTRY_URL}/api/v1/instances returned HTTP ${code}"
  exit 1
fi

exit 0
