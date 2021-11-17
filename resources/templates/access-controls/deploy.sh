#!/bin/bash

echo "Provisioning access-control resources"

aws cloudformation deploy \
  --stack-name FisStackAccessControls \
  --template-file template.yaml \
  --no-fail-on-empty-changeset \
  --capabilities CAPABILITY_NAMED_IAM