#!/bin/bash

[ -z "$REGIOH" ] && REGION=$(aws ec2 describe-availability-zones --output text --query 'AvailabilityZones[0].[RegionName]')
[ -z "$ACCOUNT_ID" ] && ACCOUNT_ID=$(aws sts get-caller-identity --output text --query 'Account')

IMPACT_ASG_NAME=$( aws cloudformation describe-stack-resources --stack-name FisStackAsg --query "StackResources[?ResourceType=='AWS::AutoScaling::AutoScalingGroup'].PhysicalResourceId" --output text  )

aws ec2 describe-instances \
--query "Reservations[*].Instances[*].{ID:InstanceId,AZ:Placement.AvailabilityZone,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name}"  \
--filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='FisStackAsg/ASG'" \
--output table

aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names ${IMPACT_ASG_NAME} --query "AutoScalingGroups[*].AvailabilityZones" \
--output table

