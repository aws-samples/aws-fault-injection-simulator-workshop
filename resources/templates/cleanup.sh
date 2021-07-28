#!/bin/bash

set -e
set -u
set -o pipefail

REGION=$(aws ec2 describe-availability-zones --output text --query 'AvailabilityZones[0].[RegionName]')
ACCOUNT_ID=$(aws sts get-caller-identity --output text --query 'Account')

echo "Cleanup in AWS Account: ${ACCOUNT_ID}"
echo "Cleanup in Region: ${REGION}"

# Optional CiCd stack
(
    STACK_NAME=$( aws cloudformation list-stacks --query "StackSummaries[?(StackName=='CicdStack')&&(StackStatus!='DELETE_COMPLETE')].StackName" --output text )
    if [ -n "${STACK_NAME}" ]; then
        echo "Deleting optional CiCd stack"
        cd cpu-stress

        # Delete CloudFormation stack
        aws cloudformation delete-stack \
        --stack-name CicdStack
        aws cloudformation wait stack-delete-complete \
        --stack-name CicdStack
    else
        echo "Optional CiCd stack stack not found"
    fi
)

# Optional CpuStress stack
(
    STACK_NAME=$( aws cloudformation list-stacks --query "StackSummaries[?(StackName=='CpuStress')&&(StackStatus!='DELETE_COMPLETE')].StackName" --output text )
    if [ -n "${STACK_NAME}" ]; then
        echo "Deleting optional CpuStress stack"
        cd cpu-stress

        # Delete CloudFormation stack
        aws cloudformation delete-stack \
        --stack-name CpuStress
        aws cloudformation wait stack-delete-complete \
        --stack-name CpuStress
    else
        echo "Optional CpuStress stack stack not found"
    fi
)

# Stress VM stack added as CFN
(
    STACK_NAME=$( aws cloudformation list-stacks --query "StackSummaries[?(StackName=='FisCpuStress')&&(StackStatus!='DELETE_COMPLETE')].StackName" --output text )
    if [ -n "${STACK_NAME}" ]; then
        echo "Deleting CPU stress instances"
        cd cpu-stress

        # Delete CloudFormation stack
        aws cloudformation delete-stack \
        --stack-name FisCpuStress
        aws cloudformation wait stack-delete-complete \
        --stack-name FisCpuStress
    else
        echo "CPU stress stack not found"
    fi
)

# ASG stack moved to CDK
(
    echo "Deleting EC2 Autoscaling Group..."
    cd asg-cdk
    npx cdk destroy FisStackAsg --force
)

# RDS/aurora stack uses CDK
(
    echo "Deleting RDS..."
    cd rds
    npm install
    npx cdk destroy FisStackRdsAurora --force
)

# Goad stack moved to CDK
(
    echo "Deleting Load Generator..."
    cd goad-cdk
    npm install
    npx cdk destroy --force
)

# VPC stack uses CDK
(
    echo "Deleting VPC..."
    cd vpc
    npm install
    npx cdk destroy FisStackVpc --force
)

# Delete log groups because they break future deployments
(
    echo "Deleting log groups ..."
    aws logs delete-log-group --log-group-name /fis-workshop/asg-access-log || echo "Log group /fis-workshop/asg-access-log already deleted"
    aws logs delete-log-group --log-group-name /fis-workshop/asg-error-log || echo "Log group /fis-workshop/asg-error-log already deleted"
)

# Remove cdk context files
(
    rm */cdk.context.json
)

echo Done.
