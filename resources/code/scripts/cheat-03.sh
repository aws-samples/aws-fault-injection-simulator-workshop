#!/bin/bash

echo "Create first experiment template"

# Set required variables
export REGION=$(aws ec2 describe-availability-zones --output text --query 'AvailabilityZones[0].[RegionName]')
export ACCOUNT_ID=$(aws sts get-caller-identity --output text --query 'Account')

# install envsubst if needed
sudo yum install -y gettext

cat cheat-03/template.json | envsubst > /tmp/cheat-03.json

AWS_PAGER="" aws fis create-experiment-template --cli-input-json file:///tmp/cheat-03.json
