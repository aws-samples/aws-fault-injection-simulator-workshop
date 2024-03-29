#!/bin/bash

echo "Create workshop service role 'FisWorkshopServiceRole'"

ROLE_NAME=FisWorkshopServiceRole

EXISTS=$( aws iam list-roles --query "Roles[?RoleName=='${ROLE_NAME}'].RoleName" --output text )

if [ -z "$EXISTS" ]; then
    aws iam create-role \
    --role-name ${ROLE_NAME} \
    --description "AutoGenerated by FIS workshop cheat codes" \
    --assume-role-policy-document file://cheat-02/workshop-trust.json

    aws iam put-role-policy \
    --role-name ${ROLE_NAME} \
    --policy-name ${ROLE_NAME} \
    --policy-document file://cheat-02/workshop-policy.json
fi