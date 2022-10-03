#!/bin/bash

echo "Setting variables from EKS section"

# Query URL for convenience
export EKS_URL=$( aws cloudformation describe-stacks --stack-name FisStackEks --query "Stacks[*].Outputs[?OutputKey=='FisEksUrl'].OutputValue" --output text )

# Retrieve the role ARN
export KUBECTL_ROLE=$( aws cloudformation describe-stacks --stack-name FisStackEks --query "Stacks[*].Outputs[?OutputKey=='FisEksKubectlRole'].OutputValue" --output text )

# Configure kubectl with cluster name and ARN
aws eks update-kubeconfig --name FisWorkshop-EksCluster --role-arn ${KUBECTL_ROLE}