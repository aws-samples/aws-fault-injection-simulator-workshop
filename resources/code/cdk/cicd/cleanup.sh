#!/bin/bash

set -e
set -u
set -o pipefail

echo "Cleaning up CI/CD stack resources"
echo "FAIL" > cleanup-status.txt
npm install
npx cdk destroy CicdStack --force
echo "OK" > cleanup-status.txt

