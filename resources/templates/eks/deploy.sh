#!/bin/bash

echo "Provisioning EKS resources"
echo "FAIL" > deploy-status.txt
npm install
npx cdk deploy FisStackEks --require-approval never --outputs-file outputs.json
echo "OK" > deploy-status.txt

