#!/bin/bash

echo "Provisioning ASG resources"
echo "FAIL" > deploy-status.txt
npm install
npx cdk deploy FisStackAsg --require-approval never --outputs-file outputs.json
echo "OK" > deploy-status.txt
