#!/bin/bash

echo "Create first experiment template"

# Set required variables
export REGION=$(aws ec2 describe-availability-zones --output text --query 'AvailabilityZones[0].[RegionName]')
export ACCOUNT_ID=$(aws sts get-caller-identity --output text --query 'Account')

# check if we already have a correctly named template
export TEMPLATE_NAME="FisWorkshopExp1Run1"

EXISTS=$( aws fis list-experiment-templates --query "experimentTemplates[?tags.Name=='${TEMPLATE_NAME}'].id" --output text )

if [ -z "$EXISTS" ]; then

    # install envsubst if needed
    sudo yum install -y gettext

    cat cheat-03/template.json | envsubst > /tmp/cheat-03.json

    AWS_PAGER="" aws fis create-experiment-template --cli-input-json file:///tmp/cheat-03.json
else
    echo "Template exists with ID ${EXISTS}"
fi