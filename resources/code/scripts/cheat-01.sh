#!/bin/bash

echo "Populating load generator lambda variables"

# Get resource information
export LAMBDA_ARN=$( aws cloudformation describe-stacks --stack-name FisStackLoadGen --query "Stacks[*].Outputs[?OutputKey=='LoadGenArn'].OutputValue" --output text )
export URL_HOME=$( aws cloudformation describe-stacks --stack-name FisStackAsg --query "Stacks[*].Outputs[?OutputKey=='FisAsgUrl'].OutputValue" --output text )
export URL_PHP=${URL_HOME}/phpinfo.php

echo LAMBDA_ARN=$LAMBDA_ARN
echo URL_HOME=$URL_HOME
echo URL_PHP=$URL_PHP

# Workaround for AWS CLI v1/v2 compatibility issues
export CLI_MAJOR_VERSION=$( aws --version | grep '^aws-cli' | cut -d/ -f2 | cut -d. -f1 )
if [ "$CLI_MAJOR_VERSION" == "2" ]; then FIX_CLI_PARAM="--cli-binary-format raw-in-base64-out"; else unset FIX_CLI_PARAM; fi