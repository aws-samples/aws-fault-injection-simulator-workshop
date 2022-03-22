#!/bin/bash

URL=$1
if [ -z "${URL}" ]; then
  echo "USAGE: $0 API_URL"
  exit 1
fi

while [ 1 ]; do 
  curl -w " - %{response_code} - %{time_total}\n" ${URL}
  sleep 1
done
