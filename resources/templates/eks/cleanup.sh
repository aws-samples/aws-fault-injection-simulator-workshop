#!/bin/bash

set -e
set -u
set -o pipefail

echo "Cleaning up EKS resources"
echo "FAIL" > cleanup-status.txt
npm install
npx cdk destroy FisStackEks --force
echo "OK" > cleanup-status.txt

