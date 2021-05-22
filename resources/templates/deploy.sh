#!/bin/bash
#
# This is a hack for development and assembly. Eventually there should be a single template 
# to deploy

MODE=${1:-"create"}
case $MODE in
    deploy|update)
        echo "Deploy mode: $MODE"
        ;;
    delete)
        echo "Deleting all stacks not curently implemented"
        exit 1
        ;;
    *)
        echo "Please select one of create / update"
        exit 1
        ;;
esac

# vpc stack uses cdk to synth
(
    cd vpc
    npm install
    cdk deploy FisStackVpc --require-approval never --outputs-file outputs.json
)

# Goad stack uses sam
(
    cd goad-redux/go-lambda
    sam build
    if [ ${MODE} == "create" ]; then
        sam deploy --stack-name FisGoad --guided
    else
        sam deploy --stack-name FisGoad
    fi
    aws cloudformation describe-stacks --stack-name FisGoad --query 'Stacks[0].Outputs' > outputs.json
)

# asg stack is straight CFN - could be converted to cdk but cfn-init support in cdk is unclear
(
    cd asg
    jq \
        --argfile a1 ../vpc/outputs.json \
        --argfile a2 ../goad-redux/go-lambda/outputs.json \
        -n \
        '[
            { 
                "ParameterKey": "NginxVpcId",
                "ParameterValue": $a1.FisStackVpc.FisVpcId
            },
            { 
                "ParameterKey": "BackendSubnets",
                "ParameterValue": ( $a1.FisStackVpc.FisPriv1 + "," + $a1.FisStackVpc.FisPriv2 )
            },
            { 
                "ParameterKey": "AlbSubnets",
                "ParameterValue": ( $a1.FisStackVpc.FisPub1 + "," + $a1.FisStackVpc.FisPub2 )
            },
            { 
                "ParameterKey": "LoadGenFunctionName",
                "ParameterValue": ( $a2[] | select( .OutputKey == "LoadGenName" ).OutputValue )
            }
        ]' > params.json
    
    aws cloudformation ${MODE}-stack \
        --stack-name FisStackAsg \
        --template-body file://fis-ec2-nginx-asg.template.yaml \
        --parameters file://params.json \
        --capabilities CAPABILITY_IAM
    aws cloudformation wait stack-${MODE}-complete \
        --stack-name FisStackAsg


)

echo next step
