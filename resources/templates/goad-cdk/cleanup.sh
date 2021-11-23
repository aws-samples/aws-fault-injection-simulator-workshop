#!/bin/bash

set -e
set -u
set -o pipefail

echo "Cleaning up load generator (goad) resources"
echo "FAIL" > cleanup-status.txt
npm install
npx cdk destroy FisStackLoadGen --force
echo "OK" > cleanup-status.txt

