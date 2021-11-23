#!/bin/bash

set -e
set -u
set -o pipefail

echo "Cleaning up access-control resources"

echo "FAIL" > cleanup-status.txt

STACK_NAME=$( aws cloudformation list-stacks --query "StackSummaries[?(StackName=='FisStackAccessControls')&&(StackStatus!='DELETE_COMPLETE')].StackName" --output text )
if [ -n "${STACK_NAME}" ]; then
    echo "... deleting"

    aws cloudformation delete-stack \
        --stack-name FisStackAccessControls
    aws cloudformation wait stack-delete-complete \
        --stack-name FisStackAccessControls
else
    echo "... no deletable stack found, skipping"
fi

echo "OK" > cleanup-status.txt
