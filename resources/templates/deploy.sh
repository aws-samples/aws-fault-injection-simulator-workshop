#!/bin/bash

set -e
set -u
set -o pipefail

#
# This is a hack for development and assembly. Eventually there should be a single template 
# to deploy

MODE=${1:-"create"}
case $MODE in
    create|update)
        echo "Deploy mode: $MODE"
        ;;
    delete)
        echo "Deleting all stacks not curently implemented"
        exit 1
        ;;
    *)
        echo "Please select one of create / update"
        exit 1
        ;;
esac

REGION=$(aws ec2 describe-availability-zones --output text --query 'AvailabilityZones[0].[RegionName]')
ACCOUNT_ID=$(aws sts get-caller-identity --output text --query 'Account')

echo "Deploying to AWS Account: ${ACCOUNT_ID}"
echo "Deploying to Region: ${REGION}"

echo "Boostrapping account with CDK"
cdk bootstrap aws://${ACCOUNT_ID}/${REGION}

# VPC stack uses CDK
(
    echo "Provisioning VPC..."
    cd vpc
    npm install
    npx cdk deploy FisStackVpc --require-approval never --outputs-file outputs.json
)

# Goad stack moved to CDK
(
    echo "Provisioning Load Generator..."
    cd goad-cdk
    npm install
    npx cdk deploy FisStackLoadGen --require-approval never --outputs-file outputs.json
)

# RDS/aurora stack uses CDK
# ... depends on VPC
(
    echo "Provisioning RDS..."
    cd rds
    npm install
    npx cdk deploy FisStackRdsAurora --require-approval never --outputs-file outputs.json
)

# ASG stack moved to CDK
# ... depends on VPC
(
    echo "Provisioning EC2 Autoscaling Group..."
    cd asg-cdk
    npm install
    npx cdk deploy FisStackAsg --require-approval never --outputs-file outputs.json
)

# EKS stack uses CDK
(
    echo "Provisioning EKS resources..."
    cd eks
    npm install
    npx cdk deploy FisStackEks --require-approval never --outputs-file outputs.json
)
# ECS stack uses CDK
(
    echo "Provisioning ECS resources..."
    cd ecs
    npm install
    npx cdk deploy FisStackEcs --require-approval never --outputs-file outputs.json
)

# Stress VM stack added as CFN
# ... depends on VPC
(
    echo "Provisioning CPU stress instances"
    cd cpu-stress
    # Query public subnet from VPC stack
    SUBNET_ID=$( aws ec2 describe-subnets --query "Subnets[?Tags[?(Key=='aws-cdk:subnet-name') && (Value=='FisPub') ]] | [0].SubnetId" --output text )

    # Launch CloudFormation stack
    aws cloudformation ${MODE}-stack \
    --stack-name FisCpuStress \
    --template-body file://CPUStressInstances.yaml  \
    --parameters \
        ParameterKey=SubnetId,ParameterValue=${SUBNET_ID} \
    --capabilities CAPABILITY_IAM
)

echo Done.
