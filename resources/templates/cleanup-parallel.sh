#!/bin/bash

set -e
set -u
set -o pipefail

REGION=$(aws ec2 describe-availability-zones --output text --query 'AvailabilityZones[0].[RegionName]')
ACCOUNT_ID=$(aws sts get-caller-identity --output text --query 'Account')

echo "Cleanup in AWS Account: ${ACCOUNT_ID}"
echo "Cleanup in Region: ${REGION}"

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

# ECS using CDK
echo "Deleting ECS..."
(
    cd ecs
    npx cdk destroy FisStackEcs --force
) > cleanup-output.ecs.txt 2>&1 &

# EKS using CDK
echo "Deleting EKS..."
(
    cd ecs
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
    aws logs delete-log-group --log-group-name /fis-workshop/asg-access-log || echo "Log group /fis-workshop/asg-access-log already deleted"
    aws logs delete-log-group --log-group-name /fis-workshop/asg-error-log || echo "Log group /fis-workshop/asg-error-log already deleted"
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
