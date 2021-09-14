#!/bin/bash

set -e
set -u
set -o pipefail

REGION=$(aws ec2 describe-availability-zones --output text --query 'AvailabilityZones[0].[RegionName]')
ACCOUNT_ID=$(aws sts get-caller-identity --output text --query 'Account')

echo "Cleanup in AWS Account: ${ACCOUNT_ID}"
echo "Cleanup in Region: ${REGION}"

# Optional demo infrastructure stack used in the CiCd lab
(
    STACK_NAME=$( aws cloudformation list-stacks --query "StackSummaries[?(StackName=='fisWorkshopDemo')&&(StackStatus!='DELETE_COMPLETE')].StackName" --output text )
    if [ -n "${STACK_NAME}" ]; then
        echo "Deleting demo infrastructure stack used in the CiCd lab"

        # Delete CloudFormation stack
        aws cloudformation delete-stack \
        --stack-name fisWorkshopDemo
        aws cloudformation wait stack-delete-complete \
        --stack-name fisWorkshopDemo
    else
        echo "Demo infrastructure stack used in the CiCd lab not found"
    fi
)

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

# Fault stacks added as CFN
(
    STACK_NAME=$( aws cloudformation list-stacks --query "StackSummaries[?(StackName=='FisApiFailureUnavailable')&&(StackStatus!='DELETE_COMPLETE')].StackName" --output text )
    if [ -n "${STACK_NAME}" ]; then
        echo "Deleting API faulrt injections stack FisApiFailureUnavailable"

        # Delete CloudFormation stack
        aws cloudformation delete-stack \
        --stack-name FisApiFailureUnavailable
        aws cloudformation wait stack-delete-complete \
        --stack-name FisApiFailureUnavailable
    else
        echo "API fault injection stack FisApiFailureUnavailable not found"
    fi

    STACK_NAME=$( aws cloudformation list-stacks --query "StackSummaries[?(StackName=='FisApiFailureThrottling')&&(StackStatus!='DELETE_COMPLETE')].StackName" --output text )
    if [ -n "${STACK_NAME}" ]; then
        echo "Deleting API faulrt injections stack FisApiFailureThrottling"

        # Delete CloudFormation stack
        aws cloudformation delete-stack \
        --stack-name FisApiFailureThrottling
        aws cloudformation wait stack-delete-complete \
        --stack-name FisApiFailureThrottling
    else
        echo "API fault injection stack FisApiFailureThrottling not found"
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

# ECS using CDK
(
    echo "Deleting ECS..."
    cd ecs
    npx cdk destroy FisStackEcs --force
)

# EKS using CDK
(
    echo "Deleting EKS..."
    cd eks
    npx cdk destroy FisStackEks --force
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
    set +e
    set +u
    set +o pipefail

    echo "Deleting log groups ..."
    aws logs delete-log-group \
        --log-group-name /fis-workshop/asg-access-log \
    || echo "Log group /fis-workshop/asg-access-log already deleted"
    aws logs delete-log-group \
        --log-group-name /fis-workshop/asg-error-log \
    || echo "Log group /fis-workshop/asg-error-log already deleted"
)

# Remove cdk context files
(
    rm */cdk.context.json
)

echo Done.
