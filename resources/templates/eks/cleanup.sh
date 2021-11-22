#!/bin/bash

echo "Cleaning up EKS resources"
echo "FAIL" > cleanup-status.txt
npm install
npx cdk destroy FisStackEks --force
echo "OK" > cleanup-status.txt

