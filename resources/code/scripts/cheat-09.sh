#!/bin/bash

echo "Create FIS template for DOP313"

# Set required variables
export DOP313_TEMPLATE_NAME=FisWorkshopDop313

export DOP313_SSM_DOCUMENT_NAME=TerminateAsgInstancesWithSsm
export DOP313_SSM_DOCUMENT_ARN=arn:aws:ssm:${REGION}:${ACCOUNT_ID}:document/${SSM_DOCUMENT_NAME}
export REGION=$(aws ec2 describe-availability-zones --output text --query 'AvailabilityZones[0].[RegionName]')
export ACCOUNT_ID=$(aws sts get-caller-identity --output text --query 'Account')

export DOP313_ASG_NAME=$( aws cloudformation describe-stack-resources --stack-name FisStackAsg --query "StackResources[?ResourceType=='AWS::AutoScaling::AutoScalingGroup'].PhysicalResourceId" --output text  )
export DOP313_AZ_OPTIONS=$( aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names ${DOP313_ASG_NAME} --query "AutoScalingGroups[*].AvailabilityZones" --output text )
export DOP313_AZ_NAME=$( aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names ${DOP313_ASG_NAME} --query "AutoScalingGroups[*].AvailabilityZones[0]" --output text )

export FIS_ROLE_NAME=FisWorkshopServiceRole
export SSM_ROLE_NAME=FisWorkshopSsmEc2DemoRole

export FIS_ROLE_ARN=$( aws iam list-roles --query "Roles[?RoleName=='${FIS_ROLE_NAME}'].Arn" --output text )
export SSM_ROLE_ARN=$( aws iam list-roles --query "Roles[?RoleName=='${SSM_ROLE_NAME}'].Arn" --output text )

EXISTS=$( aws fis list-experiment-templates --query "experimentTemplates[?tags.Name=='${TEMPLATE_NAME}'].id" --output text )

if [ -z "$EXISTS" ]; then

    cat cheat-09/template.json | envsubst > /tmp/cheat-09.json

    aws fis create-experiment-template \
    --cli-input-json file:///tmp/cheat-09.json
else
    echo "Template exists with ID ${EXISTS}"
fi
  
