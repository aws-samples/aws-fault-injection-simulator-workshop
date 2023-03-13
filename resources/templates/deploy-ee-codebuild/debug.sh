#!/bin/bash

AWS_ACCOUNT=$( aws sts get-caller-identity --query 'Account' --output text )

echo "${AWS_ACCOUNT}: Exporting cloudformation stacks that were created and their state"
aws cloudformation list-stacks > ee-debug.${AWS_ACCOUNT}.stacks.txt 2>&1

echo "${AWS_ACCOUNT}: Exporting codebuild history"
LOG_GROUPS=$( aws logs describe-log-groups --log-group-name-prefix /aws/codebuild/ --query 'logGroups[*].logGroupName' --output text )
for ii in ${LOG_GROUPS}; do
  LOG_STREAMS=$( aws logs describe-log-streams --log-group-name ${ii} --query 'logStreams[*].logStreamName' --output text )
  for jj in ${LOG_STREAMS}; do
    echo === ${ii} === ${jj} ===
    echo === ${ii} === ${jj} === >> ee-debug.${AWS_ACCOUNT}.codebuild.txt
    aws logs get-log-events --log-group-name ${ii} --log-stream-name ${jj} >> ee-debug.${AWS_ACCOUNT}.codebuild.txt 2>&1 
  done
done

echo "${AWS_ACCOUNT}: Exporting custom resource lambda history"
LOG_GROUPS=$( 
  aws logs describe-log-groups --log-group-name-prefix /aws/lambda/mod- --query 'logGroups[*].logGroupName' --output text;  
  aws logs describe-log-groups --log-group-name-prefix /aws/lambda/github-loader-template- --query 'logGroups[*].logGroupName' --output text;  
  aws logs describe-log-groups --log-group-name-prefix /aws/lambda/EE- --query 'logGroups[*].logGroupName' --output text;  
)
for ii in ${LOG_GROUPS}; do
  LOG_STREAMS=$( aws logs describe-log-streams --log-group-name ${ii} --query 'logStreams[*].logStreamName' --output text )
  for jj in ${LOG_STREAMS}; do
    echo === ${ii} === ${jj} ===
    echo === ${ii} === ${jj} === >> ee-debug.${AWS_ACCOUNT}.custom-lambda.txt
    aws logs get-log-events --log-group-name ${ii} --log-stream-name ${jj} >> ee-debug.${AWS_ACCOUNT}.custom-lambda.txt 2>&1 
  done
done

echo "${AWS_ACCOUNT}: Exporting role information"
for ii in TeamRole OpsRole; do
  echo === ${ii} === >> ee-debug.${AWS_ACCOUNT}.roles.txt
  aws iam get-role --role-name TeamRole >> ee-debug.${AWS_ACCOUNT}.roles.txt 2>&1 
  aws iam list-role-policies --role-name TeamRole >> ee-debug.${AWS_ACCOUNT}.roles.txt 2>&1 
  aws iam list-attached-role-policies --role-name TeamRole >> ee-debug.${AWS_ACCOUNT}.roles.txt 2>&1 
done


