#!/bin/bash
#
# This is a hack for development and assembly. Eventually there should be a single template 
# to deploy

# MODE=${1:-"create"}
# case $MODE in
#     deploy|update)
#         echo "Deploy mode: $MODE"
#         ;;
#     delete)
#         echo "Deleting all stacks not curently implemented"
#         exit 1
#         ;;
#     *)
#         echo "Please select one of create / update"
#         exit 1
#         ;;
# esac

# VPC stack uses CDK
(
    cd vpc
    npm install
    npx cdk deploy FisStackVpc --require-approval never --outputs-file outputs.json
)

# Goad stack moved to CDK
(
    cd goad-cdk
    npm install
    npx cdk deploy FisStackLoadGen --require-approval never --outputs-file outputs.json
)

# RDS/aurora stack uses CDK
(
    cd rds
    npm install
    npx cdk deploy FisStackRdsAurora --require-approval never --outputs-file outputs.json
)

# ASG stack moved to CDK
(
    cd asg-cdk
    npm install
    npx cdk deploy FisStackAsg --require-approval never --outputs-file outputs.json
)

echo next step
