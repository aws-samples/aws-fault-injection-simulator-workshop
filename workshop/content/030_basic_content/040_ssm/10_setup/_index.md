+++
title = "CPU Stress Test Setup"
date =  2021-07-07T17:25:37-06:00
weight = 10
+++

For this section we will use Linux and Windows instances created specifically for the purpose of enabling FIS SSM commands. As shown in the diagram below, SSM access to the instance [requires an instance role](https://docs.aws.amazon.com/systems-manager/latest/userguide/setup-instance-profile.html#instance-profile-policies-overview) with the `AmazonSSMManagedInstanceCore` policy attached. Additionally FIS access to SSM is controlled via the execution policy as shown in the [**First Experiment**]({{< ref "030 basic experiment" >}}) section. 

{{< img StressTest-with-user.png >}}



In this section we will deploy EC2 Instances using CloudFormation and the AWS CLI. 

## Deploy a Linux and Windows EC2 Instance

We will use the AWS CLI with CloudFormation to provision our instances. You can inspect the template to see how it creates an instance role with 
the AWS Managed policy named *AmazonSSMManagedInstanceCore* attached, and how it attaches it to our instances via an Instance Profile. 

Using the Cloud9 instance you created in the **Start the workshop** section, clone the repository if you have not done so yet:

```
cd ~/environment
git clone https://github.com:aws-samples/aws-fault-injection-simulator-workshop.git
```

Next change directory into the templates folder.

```
cd aws-fault-injection-simulator-workshop/resources/templates/cpu-stress/
```

In this folder you can examine the template file named `CPUStressInstances.yaml`.

Finally lets deploy our stack.


{{% notice info %}}
If you are running this workshop at an AWS event the stack has already been created for you and you can continue in the next section.
{{% /notice %}}

To ensure the instances are deployed into a public subnet, we will use the first public subnet created by the initial setup. You could do this manually by navigating to the [CloudFormation console](https://us-east-2.console.aws.amazon.com/cloudformation/home?region=us-east-2#/stacks?filteringStatus=active&filteringText=FisStackVpc&viewNested=true&hideStacks=false), selecting the `FisStackVpc` stack, selecting `Outputs` and picking the subnet ID associated with `FisPub1`. For your convenience we've added that as a CLI query in the code below:

```
# Query public subnet from VPC stack
SUBNET_ID=$( aws ec2 describe-subnets --query "Subnets[?Tags[?(Key=='aws-cdk:subnet-name') && (Value=='FisPub') ]] | [0].SubnetId" --output text )

# 
aws cloudformation create-stack \
  --stack-name FisCpuStress \
  --template-body file://CPUStressInstances.yaml  \
  --parameters \
    ParameterKey=SubnetId,ParameterValue=${SUBNET_ID} \
  --capabilities CAPABILITY_IAM

```

The stack will take a few minutes to complete. 
You can monitor the progress from the CloudFormation Console. 
Once this is finished you can continue to the next section.

