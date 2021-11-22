#!/bin/bash

echo "Cleaning up spot resources"
echo "FAIL" > cleanup-status.txt

STACK_NAME=$( aws cloudformation list-stacks --query "StackSummaries[?(StackName=='FisSpotTest')&&(StackStatus!='DELETE_COMPLETE')].StackName" --output text )
if [ -n "${STACK_NAME}" ]; then
    echo "... deleting"

    aws cloudformation delete-stack \
        --stack-name FisSpotTest
    aws cloudformation wait stack-delete-complete \
        --stack-name FisSpotTest
else
    echo "... no deletable stack found, skipping"
fi

echo "OK" > cleanup-status.txt
