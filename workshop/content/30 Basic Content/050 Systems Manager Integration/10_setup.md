+++
title = "Cpu Stress Test Setup"
date =  2021-07-07T17:25:37-06:00
weight = 10
+++

In this section we will deploy EC2 Instances using CloudFormation and the AWS CLI. 

## Deploy a Single EC2 Instance

We will use the AWS CLI to provision our instances using CloudFormation. The reason we are using CloudFormation is beside the instance we need to create an Instance role that will allow the EC2 Instance interact with the AWS Systems Manager service. When we created the role we are attaching the AWS Managed policy named *AmazonSSMManagedInstanceCore*.


First start by cloning the repository for the workshop.

```
cd ~/environment
git clone https://github.com:aws-samples/aws-fault-injection-simulator-workshop.git
```

Next change directory into the templates folder.

```
cd aws-fault-injection-simulator-workshop/resources/templates/cpu-stress/
```

Finally lets deploy our stack, choose the command for the Operating System you want to run this test against.

## Setup

The template below will deploy the roles needed for the experiments, a windows instance and a linux instance. 

```
aws cloudformation create-stack --stack-name CpuStress --template-body file://CPUStressInstances.yaml  --parameters ParameterKey=ImageId,ParameterValue=/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2 --capabilities CAPABILITY_IAM
```

The stack will take a few minutes to complete. 
You can monitor the progress from the CloudFormation Console. 
Continue to the next section.