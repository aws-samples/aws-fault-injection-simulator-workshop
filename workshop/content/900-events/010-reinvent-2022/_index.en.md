---
title: "re:invent 2022 - DOP313"
chapter: false
weight: 10
services: true
draft: true
---

The instructions collected here are aligned with a specific session at re:Invent 2022 for your convenience. These labs draw on other sections of the workshop and you may choose to explore those other sections further. 

This builder session is targeted at 300 level. We assume that you are familiar with the use of the AWS console and have familiarity with CloudWatch Dashboards. 

## Lab 1 - Review basic FIS experiment (5-10min)

We hope that you have tried FIS before but might need a refresher. Since we are assuming that you have an understanding how to create resources in AWS in general, let's use some automation to create the basic FIS experiment.

### Pre-create resources

* On the AWS console, navigate to [**AWS CloudShell**](https://console.aws.amazon.com/cloudshell/home) - see [**Configure AWS Cloudshell**]({{<ref "020_starting_workshop/020_aws_event/cloudshell" >}}) for more details

* Initialize the environment and check out the GitHub repository
  ```bash
  mkdir -p ~/environment
  cd ~/environment
  git clone https://github.com/aws-samples/aws-fault-injection-simulator-workshop.git
  ```

* Ensure you have up to date utilities installed
  ```bash
  # Update to the latest stable release of npm and nodejs.
  sudo npm install -g stable 

  # Install typescript
  sudo npm install -g typescript

  # Install CDK
  sudo npm install -g aws-cdk

  # Install the jq tool
  sudo yum install -y jq gettext
  ```

* Create server role and populate environment variables
  ```bash
  source ~/environment/aws-fault-injection-simulator-workshop/resources/code/scripts/cheat.sh 1 2 3
  ```

Your environment should now be in a similar state to where you would have been after doing the following steps in the workshop:

* [**Baselining and Monitoring**]({{<ref "030_basic_content/010-baselining">}})
* [**Synthetic User Experience**]({{<ref "030_basic_content/020_working_under_load">}})
* [**First Experiment / Configuring Permissions**]({{<ref "030_basic_content/030_basic_experiment/10-permissions">}})
* [**First Experiment / Experiment (Console)**]({{<ref "030_basic_content/030_basic_experiment/20-experiment-console" >}})

### Exploring FIS

Let's explore the experiment template that was created for you. Navigate to the [**FIS console**](https://console.aws.amazon.com/fis/home?#ExperimentTemplates:v=3&tag:Name=FisWorkshopExp1Run1) and search for a template named `FisWorkshopExp1Run1`. Select the template ID:

{{< img "dop313-template-find.png" "Find FIS template" >}}

Select "Update" to explore how the template is configured, then follow the validation procedure from the [**First Experiment section**]({{<ref "030_basic_content/030_basic_experiment/20-experiment-console#validation-procedure">}}).

{{< img "dop313-template-modify-and-run.png" "Explore FIS template" >}}


## Lab 2 - Extend FIS with AWS Systems Manager (5-10min)

### Pre-create resources

In this section we explore how to extend FIS to use AWS Systems Manager (SSM) automation documents. Let's use some automation to pre-create the required IAM role. Please ensure that you've performed the pre-creation steps in the previous section as well:

* On the AWS console, navigate to [**AWS CloudShell**](https://console.aws.amazon.com/cloudshell/home) - see [**Configure AWS Cloudshell**]({{<ref "020_starting_workshop/020_aws_event/cloudshell" >}}) for more details

* Create SSM role and populate environment variables
  ```bash
  source ~/environment/aws-fault-injection-simulator-workshop/resources/code/scripts/cheat.sh 5
  ```

Your environment should now be in a similar state to where you would have been after creating the `FisWorkshopSsmEc2DemoRole` SSM role and updating the `FisWorkshopServiceRole` as described in [**FIS SSM Start Automation Setup**]({{<ref "030_basic_content/040_ssm/050_direct_automation#configure-permissions">}}). 

### Exploring FIS + SSM

In the previous lab you terminated an EC2 instance in an auto-scaling group by filtering on a `Name` tag. In this section we will show you how to use an SSM automation document that takes an autoscaling group ARN and an AZ name to achieve the same thing.

Follow the instructions in the [**Create SSM document**]({{<ref "030_basic_content/040_ssm/050_direct_automation#create-ssm-document">}}) section of the **FIS SSM Start Automation Setup** page. You should now have an SSM document. Navigate to the [**SSM console**](https://console.aws.amazon.com/systems-manager/documents), select "Documents" at the bottom of the burger menu, then select "Owned by me" and search for `TerminateAsgInstancesWithSsm`. 

{{< img "dop313-ssm-find.png" "Explore SSM template" >}}

Now we need to create a FIS template using our newly created SSM document. You can follow the instructions in the [**Create FIS Experiment Template**]({{<ref "030_basic_content/040_ssm/050_direct_automation#create-fis-experiment-template">}}) section of the **FIS SSM Start Automation Setup** page or you can run this script:

```bash
source ~/environment/aws-fault-injection-simulator-workshop/resources/code/scripts/cheat.sh 9
```

With the FIS template created you can now run the FIS template from the [**FIS console**](https://console.aws.amazon.com/fis/home?#ExperimentTemplates:v=3&tag:Name=FisWorkshopDop313) and observe the impact on the CloudWatch dashboard like in Lab 1. 


## Lab 3 - Explore AZ outage simulations (30-40min)

In the previous Labs, you have learned how to use built-in FIS template to terminate EC2 instances based on Tag, to inject controlled fault. You also learn how to do the same using SSM Document but this time based on AZ. SSM Document provides flexibility to design your experiment. It allows us to write custom experiment as long as we can script it! In this Lab, we are going to use SSM Document to simulate an AZ failure.

Hypothesis: If there is AZ failure, the workload is able to scale and handle incoming load increases (because we are using multi-AZ!). 

To design this experiment to your system, you need to ask yourself what it means by AZ failure? For our Web Application, AZ failure means that:
1. All the instances in the failure AZ are not able to accept the incoming load. AND
2. You are no longer able to provision EC2 instances in that AZ. 

We already have the SSM Document to terminate EC2 instances in a specify AZ from previous lab now we are going to create another SSM Document to prevent ASG to scale in the same AZ.  We are expecting ASG to scale in the available AZ to the desire number of instances and our application continue to serve the requests. 

We are going to use SSM Document available in this section. [**Simulating AZ Issues**]({{<ref "030_basic_content/090_scenarios/010_simulating_az_issues/020_impact_ec2-asg#workaround-remove-az-from-asg--lb">}})

Use the following CLI command to create the SSM document and export the document ARN:

```bash
cd ~/environment/aws-fault-injection-simulator-workshop
cd workshop/content/030_basic_content/040_ssm/050_direct_automation

SSM_DOCUMENT_NAME=RemoveAZFromAsgWithSsm

# Create SSM document
aws ssm create-document \
  --name ${SSM_DOCUMENT_NAME} \
  --document-format YAML \
  --document-type Automation \
  --content file://ssm-asg-remove-az.yaml
  
# Construct ARN
REGION=$(aws ec2 describe-availability-zones --output text --query 'AvailabilityZones[0].[RegionName]')
ACCOUNT_ID=$(aws sts get-caller-identity --output text --query 'Account')
DOCUMENT_ARN=arn:aws:ssm:${REGION}:${ACCOUNT_ID}:document/${SSM_DOCUMENT_NAME}
echo $DOCUMENT_ARN
```

Now Let's create an Experiment template that bring one AZ down

Through FIS Console

1. Navigate to FIS Console and click Create Experiment Template
2. Under "Description", enter `Simulate AZ-a Failure`.  Under "Name", enter `AZ-a Failure`.
3. Under "Actions" Section, we are going to add two actions using SSM Automation Document. Before that, run these command to get SSM Automation Document ARN.

```bash
REGION=$(aws ec2 describe-availability-zones --output text --query 'AvailabilityZones[0].[RegionName]')
ACCOUNT_ID=$(aws sts get-caller-identity --output text --query 'Account')

TerminateEC2_SSM_DOCUMENT_NAME=TerminateAsgInstancesWithSsm
TerminateEC2_DOCUMENT_ARN=arn:aws:ssm:${REGION}:${ACCOUNT_ID}:document/${TerminateEC2_SSM_DOCUMENT_NAME}
echo $TerminateEC2_DOCUMENT_ARN

RemoveAZ_SSM_DOCUMENT_NAME=RemoveAZFromAsgWithSsm
RemoveAZ_DOCUMENT_ARN=arn:aws:ssm:${REGION}:${ACCOUNT_ID}:document/${RemoveAZ_SSM_DOCUMENT_NAME}
echo $RemoveAZ_DOCUMENT_ARN
```


3.1 Terminate EC2 Instances in AZ-a
 Click "Add Action", fill the configuration with these values.
 Name: Terminate-EC2-AZa
 Action type: aws:ssm:start-automation-execution
 Document Arn:  Enter the ARN from output of the above command for Document Name "TerminateAsgInstancesWithSsm"
 Document Parameter: 
 ```json
 {
    "AvailabilityZone": "us-east-1a", 
    "AutoscalingGroupName":"<<Enter ASG Name>>", 
    "AutomationAssumeRole": "arn:aws:iam::<<Your Account Id>>:role/FisWorkshopSsmEc2DemoRole"}
 ```
Max Duration: 3 Minutes
Click "Save"
3.2 Remove AZ from ASG
 Click "Add Action", fill the configuration with these values.
 Name: Remove-AZa-From-ASG
 Action type: aws:ssm:start-automation-execution
 Document Arn:  Enter the ARN from output of the above command for Document Name "TerminateAsgInstancesWithSsm"
 Document Parameter: (Same Parameter as the previous document)
 ```json
 {
    "AvailabilityZone": "us-east-1a", 
    "AutoscalingGroupName":"<<Enter ASG Name>>", 
    "AutomationAssumeRole": "arn:aws:iam::<<Your Account Id>>:role/FisWorkshopSsmEc2DemoRole"}
 ````
Max Duration: 3 Minutes
Click "Save"
4. Click "Create Experiment Template"

Now Let's start the experiment.

1. Run this command to see all instances that are hosting our website.

```bash
aws ec2 describe-instances \
--query "Reservations[*].Instances[*].{ID:InstanceId,AZ:Placement.AvailabilityZone,Type:InstanceType,Name:Tags[?Key=='Name']|[0].Value,Status:State.Name}"  \
--filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values='FisStackAsg/ASG'"  \
--output table

```

2. In FIS Console under Experiment Template, select the template we just created then click "Start Experiment"
