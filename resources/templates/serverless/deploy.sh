#!/bin/bash

set -e
set -u
set -o pipefail

echo "Provisioning serverless resources"

echo "FAIL" > deploy-status.txt

# Workaround to let sam deploy infer template by looking in build directory
sam build \
  -t template.yaml \
  --use-container \
&& \
sam deploy \
  --stack-name FisStackServerless \
  --resolve-s3 \
  --no-fail-on-empty-changeset \
  --capabilities CAPABILITY_NAMED_IAM 

echo "OK" > deploy-status.txt
