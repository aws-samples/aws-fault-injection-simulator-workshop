#!/bin/bash

echo "Cleaning up ECS resources"
echo "FAIL" > cleanup-status.txt
npm install
npx cdk destroy FisStackEcs --force
echo "OK" > cleanup-status.txt

