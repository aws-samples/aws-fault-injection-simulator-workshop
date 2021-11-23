#!/bin/bash

set -e
set -u
set -o pipefail

echo "Cleaning up API fault resources"
echo "FAIL" > cleanup-status.txt

# Check if stack exists in some sort of deletable state
STACK_NAME=$( aws cloudformation list-stacks --query "StackSummaries[?(StackName=='FisApiFailureUnavailable')&&(StackStatus!='DELETE_COMPLETE')].StackName" --output text )
if [ -n "${STACK_NAME}" ]; then
    echo "... deleting FisApiFailureUnavailable"
    aws cloudformation delete-stack \
        --stack-name FisApiFailureUnavailable
    aws cloudformation wait stack-delete-complete \
        --stack-name FisApiFailureUnavailable
else
    echo "... no deletable FisApiFailureUnavailable stack found, skipping"
fi

# Check if stack exists in some sort of deletable state
STACK_NAME=$( aws cloudformation list-stacks --query "StackSummaries[?(StackName=='FisApiFailureThrottling')&&(StackStatus!='DELETE_COMPLETE')].StackName" --output text )
if [ -n "${STACK_NAME}" ]; then
    echo "... deleting FisApiFailureThrottling"
    aws cloudformation delete-stack \
        --stack-name FisApiFailureThrottling
    aws cloudformation wait stack-delete-complete \
        --stack-name FisApiFailureThrottling
else
    echo "... no deletable FisApiFailureThrottling stack found, skipping"
fi

echo "OK" > cleanup-status.txt
