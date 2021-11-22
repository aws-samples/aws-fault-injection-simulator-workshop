#!/bin/bash

AWS_ACCOUNT=$( aws sts get-caller-identity --query 'Account' --output text )

echo "Exporting cloudformation stacks that were created and their state"
aws cloudformation list-stacks > ee-debug.${AWS_ACCOUNT}.stacks.txt

echo "Exporting codebuild history"
LOG_GROUPS=$( aws logs describe-log-groups --log-group-name-prefix /aws/codebuild/ --query 'logGroups[*].logGroupName' --output text )
for ii in ${LOG_GROUPS}; do
  LOG_STREAMS=$( aws logs describe-log-streams --log-group-name ${ii} --query 'logStreams[*].logStreamName' --output text )
  for jj in ${LOG_STREAMS}; do
    echo === ${ii} === ${jj} ===
    echo === ${ii} === ${jj} === >> ee-debug.${AWS_ACCOUNT}.codebuild.txt
    aws logs get-log-events --log-group-name ${ii} --log-stream-name ${jj} >> ee-debug.${AWS_ACCOUNT}.codebuild.txt 2>&1 
  done
done
