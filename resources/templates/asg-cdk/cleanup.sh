#!/bin/bash

set -e
set -u
set -o pipefail

echo "Cleaning up ASG resources"
echo "FAIL" > cleanup-status.txt
npm install
npx cdk destroy FisStackAsg --force
echo "OK" > cleanup-status.txt

