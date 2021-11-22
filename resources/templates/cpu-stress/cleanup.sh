#!/bin/bash

echo "Cleaning up CPU stress resources"
echo "FAIL" > cleanup-status.txt

# Check if stack exists in some sort of deletable state
STACK_NAME=$( aws cloudformation list-stacks --query "StackSummaries[?(StackName=='FisCpuStress')&&(StackStatus!='DELETE_COMPLETE')].StackName" --output text )
if [ -n "${STACK_NAME}" ]; then
    echo "... deleting"
    aws cloudformation delete-stack \
        --stack-name FisCpuStress
    aws cloudformation wait stack-delete-complete \
        --stack-name FisCpuStress
else
    echo "... no deletable stack found, skipping"
fi

echo "OK" > cleanup-status.txt
