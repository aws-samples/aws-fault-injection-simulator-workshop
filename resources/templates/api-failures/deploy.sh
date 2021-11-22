#!/bin/bash

echo "Provisioning API failure stacks"

echo "FAIL" > deploy-status.txt

# Query public subnet from VPC stack
SUBNET_ID=$( aws ec2 describe-subnets --query "Subnets[?Tags[?(Key=='aws-cdk:subnet-name') && (Value=='FisPub') ]] | [0].SubnetId" --output text )

# Launch CloudFormation stack
echo "... FisApiFailureThrottling"
aws cloudformation deploy \
    --stack-name FisApiFailureThrottling \
    --template-file api-throttling.yaml  \
    --capabilities CAPABILITY_IAM

echo "... FisApiFailureUnavailable"
aws cloudformation deploy \
    --stack-name FisApiFailureUnavailable \
    --template-file api-unavailable.yaml  \
    --parameter-overrides \
        SubnetId=${SUBNET_ID} \
    --capabilities CAPABILITY_IAM

echo "OK" > deploy-status.txt
