#!/bin/bash

sam deploy \
  -t template.yaml \
  --stack-name FisSpotTest \
  --resolve-s3 \
  --no-fail-on-empty-changeset \
  --capabilities CAPABILITY_IAM