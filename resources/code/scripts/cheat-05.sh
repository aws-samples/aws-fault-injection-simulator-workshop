#!/bin/bash

echo "Create workshop service role for SSM"

export FIS_ROLE_NAME=FisWorkshopServiceRole
export SSM_ROLE_NAME=FisWorkshopSsmEc2DemoRole

export FIS_ROLE_ARN=$( aws iam list-roles --query "Roles[?RoleName=='${FIS_ROLE_NAME}'].Arn" --output text )
export SSM_ROLE_ARN=$( aws iam list-roles --query "Roles[?RoleName=='${SSM_ROLE_NAME}'].Arn" --output text )

if [ -z "$FIS_ROLE_ARN" ]; then
  echo "Calling depenency cheat 2"
  source cheat-02.sh
  export FIS_ROLE_ARN=$( aws iam list-roles --query "Roles[?RoleName=='${FIS_ROLE_NAME}'].Arn" --output text )
fi

if [ -z "$SSM_ROLE_ARN" ]; then

    cat cheat-03/template.json | envsubst > /tmp/cheat-03.json
    aws iam create-role \
    --role-name ${SSM_ROLE_NAME} \
    --description "AutoGenerated by FIS workshop cheat codes" \
    --assume-role-policy-document file://cheat-05/ssm-trust.json

    aws iam put-role-policy \
    --role-name ${SSM_ROLE_NAME} \
    --policy-name ${SSM_ROLE_NAME} \
    --policy-document file://cheat-05/ssm-policy.json

    export SSM_ROLE_ARN=$( aws iam list-roles --query "Roles[?RoleName=='${SSM_ROLE_NAME}'].Arn" --output text )
    # Inject SSM role into FIS policy and attach to FIS role
    cat cheat-05/workshop-policy2.json | envsubst > /tmp/workshop-policy2.json

    aws iam put-role-policy \
    --role-name ${FIS_ROLE_NAME} \
    --policy-name ${SSM_ROLE_NAME} \
    --policy-document file:///tmp/workshop-policy2.json

else
    echo "Role exists with ARN ${SSM_ROLE_ARN}"
fi
