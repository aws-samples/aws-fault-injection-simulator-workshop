#!/bin/bash

set -e
set -u
set -o pipefail

echo "Provisioning load generator (goad) resources"
echo "FAIL" > deploy-status.txt
npm install
npx cdk deploy FisStackLoadGen --require-approval never --outputs-file outputs.json
echo "OK" > deploy-status.txt
