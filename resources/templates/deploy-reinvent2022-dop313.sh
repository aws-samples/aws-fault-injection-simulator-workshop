#!/bin/bash

set -e
set -u
set -o pipefail

#
# This is a hack for development and assembly if you must use stack-create / stack-update for some reason.
# All current resources do not require this so it's commented out

# MODE=${1:-"create"}
# case $MODE in
#     create|update)
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

# Handler function to make the rest of the script more legible and consistent
# Note that this fuction will background tasks so use wait where needed
function call_deploy_script() {
    INSTALLER_DIR=$1
    INSTALLER_COMMENT=$2
    echo "Deploying from ./${INSTALLER_DIR}/: ${INSTALLER_COMMENT}"
    (
        cd ${INSTALLER_DIR}
        bash deploy.sh
    ) > deploy-output.${INSTALLER_DIR}.txt 2>&1 &
}

REGION=$(aws ec2 describe-availability-zones --output text --query 'AvailabilityZones[0].[RegionName]')
ACCOUNT_ID=$(aws sts get-caller-identity --output text --query 'Account')

echo "Deploying to AWS Account: ${ACCOUNT_ID}"
echo "Deploying to Region: ${REGION}"

echo "Boostrapping account with CDK"
cdk bootstrap aws://${ACCOUNT_ID}/${REGION}

# Clean up previous deploy record
rm -f deploy-output.*.txt */deploy-status.txt

# VPC stack uses CDK
call_deploy_script "vpc" "VPC stack" 

# VPC is needed for everything else so wait for completion
echo "Waiting for VPC stack to finish"
wait

# Plain CLI for SLR creation
call_deploy_script "slr" "Service linked role stack" 

# Goad stack moved to CDK
call_deploy_script "goad-cdk" "Load generator stack" 

# Access controls using CFN
call_deploy_script "access-controls" "Access controls stack" 

# # Serverless failures are fully self-contained SAM
# call_deploy_script "serverless" "Serverless failure stack" 


# Need to sequence construction
(
    # RDS/aurora stack uses CDK
    # ... depends on VPC
    call_deploy_script "rds" "RDS stack" 

    # RDS secrets are needed for ASG so wait for completion
    wait

    # ASG stack moved to CDK
    # ... depends on VPC
    # ... depends on RDS for secret
    call_deploy_script "asg-cdk" "ASG stack" 

    # Need to wait here to make sure outer wait has something to wait on
    wait
) &

# # EKS stack uses CDK
# # ... depends on VPC
# call_deploy_script "eks" "EKS stack" 

# # ECS stack uses CDK
# # ... depends on VPC
# call_deploy_script "ecs" "ECS stack" 

# # Stress VM stack added as CFN
# # ... depends on VPC
# call_deploy_script "cpu-stress" "CPU stress stack" 

# # API failures are plain CFN
# # ... depends on VPC
# call_deploy_script "api-failures" "API failure stack" 

# # CFN spot example using SAM
# # ... depends on VPC
# call_deploy_script "spot" "Spot instance stack" 

# Wait for everything to finish
echo "Waiting for remaining stacks and substacks to finish"
wait

EXIT_STATUS=0
for substack in \
    vpc \
    goad-cdk \
    access-controls \
    rds \
    asg-cdk \
    slr \
; do
    touch $substack/deploy-status.txt
    RES=$(cat $substack/deploy-status.txt)
    if [ "$RES" != "OK" ]; then
        echo "Substack $substack FAILED"
        EXIT_STATUS=1
    else
        echo "Substack $substack SUCCEEDED"
    fi
done

if [ ${EXIT_STATUS:=1} -eq 1 ]; then
    echo "Overall install FAILED"
else
    echo "Overall install SUCCEEDED"
fi
exit $EXIT_STATUS