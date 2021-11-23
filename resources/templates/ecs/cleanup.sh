#!/bin/bash

set -e
set -u
set -o pipefail

echo "Cleaning up ECS resources"
echo "FAIL" > cleanup-status.txt
npm install
npx cdk destroy FisStackEcs --force
echo "OK" > cleanup-status.txt

