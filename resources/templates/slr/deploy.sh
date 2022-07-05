#!/bin/bash

set -e
set -u
set -o pipefail

echo "Provisioning service linked role"

echo "FAIL" > deploy-status.txt

# Check if role exists
ROLE_COUNT=$( aws iam list-roles --path-prefix /aws-service-role/fis.amazonaws.com --query "Roles[?RoleName=='AWSServiceRoleForFIS'].RoleName" --output text | wc -l )

if [ ${ROLE_COUNT:=0} -eq 0 ]; then
  echo "Role does not exist yet, create it"
  AWS_PAGER="" aws iam create-service-linked-role --aws-service-name fis.amazonaws.com 
else
  echo "Role already exists"
fi

echo "OK" > deploy-status.txt
