#!/bin/bash

set -e
set -u
set -o pipefail

echo "Provisioning CPU stress instances"
echo "FAIL" > deploy-status.txt

# Query public subnet from VPC stack
SUBNET_ID=$( aws ec2 describe-subnets --query "Subnets[?Tags[?(Key=='aws-cdk:subnet-name') && (Value=='FisPub') ]] | [0].SubnetId" --output text )

# Launch CloudFormation stack
aws cloudformation deploy \
    --stack-name FisCpuStress \
    --template-file CPUStressInstances.yaml  \
    --parameter-overrides \
        SubnetId=${SUBNET_ID} \
    --no-fail-on-empty-changeset \
    --capabilities CAPABILITY_IAM

echo "OK" > deploy-status.txt