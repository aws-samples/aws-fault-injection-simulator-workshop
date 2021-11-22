#!/bin/bash

set -e
set -u
set -o pipefail

echo "Provisioning vpc resources"
echo "FAIL" > deploy-status.txt
npm install
npx cdk deploy FisStackVpc --require-approval never --outputs-file outputs.json
echo "OK" > deploy-status.txt

