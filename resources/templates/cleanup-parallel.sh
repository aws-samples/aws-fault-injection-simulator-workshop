#!/bin/bash

set -e
set -u
set -o pipefail

REGION=$(aws ec2 describe-availability-zones --output text --query 'AvailabilityZones[0].[RegionName]')
ACCOUNT_ID=$(aws sts get-caller-identity --output text --query 'Account')

echo "Cleanup in AWS Account: ${ACCOUNT_ID}"
echo "Cleanup in Region: ${REGION}"

# Optional demo infrastructure stack used in the CiCd lab
# This stack uses IAM role from the Cicd stack: it must be deleted before starting the deletion of the Cicd stack
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
STACK_NAME=$( aws cloudformation list-stacks --query "StackSummaries[?(StackName=='CicdStack')&&(StackStatus!='DELETE_COMPLETE')].StackName" --output text )
if [ -n "${STACK_NAME}" ]; then
    echo "Deleting optional CiCd stack"
    (
        cd cpu-stress

        # Delete CloudFormation stack
        aws cloudformation delete-stack \
        --stack-name CicdStack
        aws cloudformation wait stack-delete-complete \
        --stack-name CicdStack
    ) > cleanup-output.cicd.txt 2>&1 &
else
    echo "Optional CiCd stack stack not found"
fi

# Optional CpuStress stack
STACK_NAME=$( aws cloudformation list-stacks --query "StackSummaries[?(StackName=='CpuStress')&&(StackStatus!='DELETE_COMPLETE')].StackName" --output text )
if [ -n "${STACK_NAME}" ]; then
    echo "Deleting optional CpuStress stack"
    (
        cd cpu-stress

        # Delete CloudFormation stack
        aws cloudformation delete-stack \
        --stack-name CpuStress
        aws cloudformation wait stack-delete-complete \
        --stack-name CpuStress
    ) > cleanup-output.stressopt.txt 2>&1 &
else
    echo "Optional CpuStress stack stack not found"
fi

# Spot stack added as SAM
STACK_NAME=$( aws cloudformation list-stacks --query "StackSummaries[?(StackName=='FisSpotTest')&&(StackStatus!='DELETE_COMPLETE')].StackName" --output text )
if [ -n "${STACK_NAME}" ]; then
    echo "Deleting Spot stack"
    (
        cd spot
        bash cleanup.sh
    ) > cleanup-output.spot.txt 2>&1 &
else
    echo "Spot test stack not found"
fi

# Stress VM stack added as CFN
STACK_NAME=$( aws cloudformation list-stacks --query "StackSummaries[?(StackName=='FisCpuStress')&&(StackStatus!='DELETE_COMPLETE')].StackName" --output text )
if [ -n "${STACK_NAME}" ]; then
    echo "Deleting CPU stress instances"
    (
        cd cpu-stress

        # Delete CloudFormation stack
        aws cloudformation delete-stack \
        --stack-name FisCpuStress
        aws cloudformation wait stack-delete-complete \
        --stack-name FisCpuStress
    ) > cleanup-output.stress.txt 2>&1 &
else
    echo "CPU stress stack not found"
fi

# Fault stacks added as CFN
STACK_NAME=$( aws cloudformation list-stacks --query "StackSummaries[?(StackName=='FisApiFailureUnavailable')&&(StackStatus!='DELETE_COMPLETE')].StackName" --output text )
if [ -n "${STACK_NAME}" ]; then
    echo "Deleting API faulrt injections stack FisApiFailureUnavailable"
    (
        # Delete CloudFormation stack
        aws cloudformation delete-stack \
        --stack-name FisApiFailureUnavailable
        aws cloudformation wait stack-delete-complete \
        --stack-name FisApiFailureUnavailable
    ) > cleanup-output.api-unavailable.txt 2>&1 &
else
    echo "API fault injection stack FisApiFailureUnavailable not found"
fi

STACK_NAME=$( aws cloudformation list-stacks --query "StackSummaries[?(StackName=='FisApiFailureThrottling')&&(StackStatus!='DELETE_COMPLETE')].StackName" --output text )
if [ -n "${STACK_NAME}" ]; then
    echo "Deleting API faulrt injections stack FisApiFailureThrottling"

    (    # Delete CloudFormation stack
        aws cloudformation delete-stack \
        --stack-name FisApiFailureThrottling
        aws cloudformation wait stack-delete-complete \
        --stack-name FisApiFailureThrottling
    )  > cleanup-output.api-throttling.txt 2>&1 &
else
    echo "API fault injection stack FisApiFailureThrottling not found"
fi




# ECS using CDK
echo "Deleting ECS..."
(
    cd ecs
    npx cdk destroy FisStackEcs --force
) > cleanup-output.ecs.txt 2>&1 &

# EKS using CDK
echo "Deleting EKS..."
(
    cd eks
    npx cdk destroy FisStackEks --force
) > cleanup-output.eks.txt 2>&1 &

# ASG stack moved to CDK
echo "Deleting EC2 Autoscaling Group..."
(
    cd asg-cdk
    npx cdk destroy FisStackAsg --force
) > cleanup-output.asg.txt 2>&1 &

# RDS/aurora stack uses CDK
echo "Deleting RDS..."
(
    cd rds
    npm install
    npx cdk destroy FisStackRdsAurora --force
) > cleanup-output.rds.txt 2>&1 &

# Goad stack moved to CDK
echo "Deleting Load Generator..."
(
    cd goad-cdk
    npm install
    npx cdk destroy --force
) > cleanup-output.goad.txt 2>&1 &

# Wait before deleting VPC
echo "Waiting before starting VPC deletion"
wait

# VPC stack uses CDK
echo "Deleting VPC..."
(
    cd vpc
    npm install
    npx cdk destroy FisStackVpc --force
) > cleanup-output.vpc.txt 2>&1 &

# Delete log groups because they break future deployments
echo "Deleting log groups ..."
(
    set +e
    set +u
    set +o pipefail

    aws logs delete-log-group \
        --log-group-name /fis-workshop/asg-access-log \
    || echo "Log group /fis-workshop/asg-access-log already deleted"
    aws logs delete-log-group \
        --log-group-name /fis-workshop/asg-error-log \
    || echo "Log group /fis-workshop/asg-error-log already deleted"
) > cleanup-output.loggroups.txt 2>&1 &

# Remove cdk context files
echo "Deleting cdk state files ..."
(
    rm */cdk.context.json
) > cleanup-output.cdkstate.txt 2>&1 &

# Wait for everything to finish
echo "Waiting for finish"
wait

echo Done.
