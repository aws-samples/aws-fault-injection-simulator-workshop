#!/bin/bash

set -e
set -u
set -o pipefail

echo "Provisioning access-control resources"

echo "FAIL" > deploy-status.txt

aws cloudformation deploy \
  --stack-name FisStackAccessControls \
  --template-file template.yaml \
  --no-fail-on-empty-changeset \
  --capabilities CAPABILITY_NAMED_IAM

  echo "OK" > deploy-status.txt