#!/bin/bash

set -e
set -u
set -o pipefail

echo "Cleaning up serverless resources"
echo "FAIL" > cleanup-status.txt

STACK_NAME=$( aws cloudformation list-stacks --query "StackSummaries[?(StackName=='FisStackServerless')&&(StackStatus!='DELETE_COMPLETE')].StackName" --output text )
if [ -n "${STACK_NAME}" ]; then
    echo "... deleting"

    aws cloudformation delete-stack \
        --stack-name ${STACK_NAME}
    aws cloudformation wait stack-delete-complete \
        --stack-name ${STACK_NAME}
else
    echo "... no deletable stack found, skipping"
fi

echo "OK" > cleanup-status.txt
