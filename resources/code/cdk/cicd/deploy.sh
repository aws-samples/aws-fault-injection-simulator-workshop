#!/bin/bash

set -e
set -u
set -o pipefail

echo "Provisioning optional CiCd resources"
echo "FAIL" > deploy-status.txt
npm install
npx cdk deploy CicdStack --require-approval never --outputs-file outputs.json
echo "OK" > deploy-status.txt
