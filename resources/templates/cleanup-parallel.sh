#!/bin/bash

set -e
set -u
set -o pipefail

REGION=$(aws ec2 describe-availability-zones --output text --query 'AvailabilityZones[0].[RegionName]')
ACCOUNT_ID=$(aws sts get-caller-identity --output text --query 'Account')

echo "Cleanup in AWS Account: ${ACCOUNT_ID}"
echo "Cleanup in Region: ${REGION}"

function call_cleanup_script() {
    INSTALLER_DIR=$1
    INSTALLER_NAME=$(echo ${INSTALLER_DIR} | sed -e 's/[^a-zA-Z0-9]/-/g; s/^-*//; s/-*$//' )
    INSTALLER_COMMENT=$2
    echo "Cleanup from ${INSTALLER_DIR}: ${INSTALLER_COMMENT}"
    (
        cd ${INSTALLER_DIR}
        bash cleanup.sh
    ) > cleanup-output.${INSTALLER_NAME}.txt 2>&1 &
}

# Clean up previous cleanup record
rm -f cleanup-output.*.txt */cleanup-status.txt

# Optional demo infrastructure stack used in the CiCd lab
# This stack uses IAM role from the Cicd stack: it must be deleted before starting the deletion of the Cicd stack
call_cleanup_script "../code/cdk/cicd/" "Optional CiCd stack" 

# Stress VM stack added as CFN
call_cleanup_script "cpu-stress" "CPU stress stack" 

# Spot stack added as SAM
call_cleanup_script "spot" "Spot stack" 

# Fault stacks added as CFN
call_cleanup_script "api-failures" "API failure stacks" 



# ECS using CDK
call_cleanup_script "ecs" "ECS stack" 

# EKS using CDK
call_cleanup_script "eks" "EKS stack" 

# ASG stack moved to CDK
call_cleanup_script "asg-cdk" "ASG stack" 

# RDS/aurora stack uses CDK
call_cleanup_script "rds" "RDS stack" 

# Goad stack moved to CDK
call_cleanup_script "access-controls" "Access controls stack" 

# Goad stack moved to CDK
call_cleanup_script "goad-cdk" "Load generator (goad) stack" 

# Wait before deleting VPC
echo "Waiting before starting VPC deletion"
wait

# VPC stack uses CDK
call_cleanup_script "vpc" "VPC stack" 

# Delete log groups because they break future deployments
echo "Deleting log groups ..."
(
    set +e
    set +u
    set +o pipefail

    aws logs delete-log-group \
        --log-group-name /fis-workshop/asg-access-log \
    || echo "Log group /fis-workshop/asg-access-log already deleted"
    aws logs delete-log-group \
        --log-group-name /fis-workshop/asg-error-log \
    || echo "Log group /fis-workshop/asg-error-log already deleted"
) > cleanup-output.loggroups.txt 2>&1 &

# Remove cdk context files
echo "Deleting cdk state files ..."
(
    rm */cdk.context.json
) > cleanup-output.cdkstate.txt 2>&1 &

# Wait for everything to finish
echo "Waiting for finish"
wait

EXIT_STATUS=0
for substack in \
    ../code/cdk/cicd \
    vpc \
    goad-cdk \
    access-controls \
    serverless \
    rds \
    asg-cdk \
    eks \
    ecs \
    cpu-stress \
    api-failures \
    spot \
; do
    touch $substack/cleanup-status.txt
    RES=$(cat $substack/cleanup-status.txt)
    if [ "$RES" != "OK" ]; then
        echo "Substack $substack FAILED"
        EXIT_STATUS=1
    else
        echo "Substack $substack SUCCEEDED"
    fi
done

if [ ${EXIT_STATUS:=1} -eq 1 ]; then
    echo "Overall cleanup FAILED"
else
    echo "Overall cleanup SUCCEEDED"
fi
exit $EXIT_STATUS