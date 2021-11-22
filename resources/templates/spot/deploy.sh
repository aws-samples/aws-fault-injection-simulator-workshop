#!/bin/bash

set -e
set -u
set -o pipefail

echo "Provisioning spot resources"

echo "FAIL" > deploy-status.txt

# Use subnet from workshop deploy
SUBNET_ID=$( aws ec2 describe-subnets --query "Subnets[?Tags[?(Key=='aws-cdk:subnet-name') && (Value=='FisPriv') ]] | [0].SubnetId" --output text )

# Normally it should be possible to just pass the parameterstore string to an AWS::EC2::Image::Id parameter but found at least one account where that's broken
AMI_ID=$( aws ssm get-parameters --names /aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-ebs --query 'Parameters[0].Value' --output text)

sam deploy \
  -t template.yaml \
  --stack-name FisSpotTest \
  --resolve-s3 \
  --no-fail-on-empty-changeset \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides "SubnetId=${SUBNET_ID} ImageId=${AMI_ID}"

echo "OK" > deploy-status.txt
