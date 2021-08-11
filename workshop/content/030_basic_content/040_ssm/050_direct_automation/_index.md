+++
title = "FIS SSM Start Automation Setup"
weight = 50
+++

In the previous sections we used FIS actions to directly interact with AWS APIs to terminate EC2 instances, and the [SSM SendCommand](https://docs.aws.amazon.com/systems-manager/latest/APIReference/API_SendCommand.html) option to execute code directly on our virtual machines. 

In this section we will cover how to execute additional actions against AWS APIs that are not yet supported by by FIS by using [SSM Runbooks](https://docs.aws.amazon.com/systems-manager/latest/userguide/automation-documents.html).


{{< img "StressTest-with-runbook.png" "Stress test architecture" >}}

## Configure permissions


In the [Configuring Permissions]({{< ref "030_basic_content/030_basic_experiment/10-permissions" >}}) section we defined a service role `FisWorkshopServiceRole` that granted us access to running the FIS `aws:ssm:send-command` on our instances. To use the `aws:ssm:start-automation-execution` action we will need to update our permissions

### Create SSM role

As shown in the image above, SSM Runbooks require us to define and pass a separate role. Let's say we want to create an SSM document that can terminate instances in an autoscaling group. A policy for that might need the following permissions:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "EnableAsgDocument",
            "Effect": "Allow",
            "Action": [
                "autoscaling:DescribeAutoScalingGroups",
                "autoscaling:SuspendProcesses",
                "autoscaling:ResumeProcesses",
                "ec2:DescribeInstances",
                "ec2:DescribeInstanceStatus",
                "ec2:TerminateInstances"
            ],
            "Resource": "*"
        }
    ]
}
```

Since SSM needs to be able to assume this role for running an SSM document we also need to define a trust policy:

```json
{
    "Version": "2012-10-17",
    "Statement": {
        "Effect": "Allow",
        "Principal": {
            "Service": "ssm.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
    }
}
```

To create a role, save the two JSON block above into files named `iam-ec2-demo-policy.json` and `iam-ec2-demo-trust.json` and run the following CLI commands to create a role named `FisWorkshopSsmEc2DemoRole`

```bash
ROLE_NAME=FisWorkshopSsmEc2DemoRole

aws iam create-role \
  --role-name ${ROLE_NAME} \
  --assume-role-policy-document file://iam-ec2-demo-trust.json

aws iam put-role-policy \
  --role-name ${ROLE_NAME} \
  --policy-name ${ROLE_NAME} \
  --policy-document file://iam-ec2-demo-policy.json
```

Note the ARN of the created role as we will need it below.

### Update FIS service role

The `FisWorkshopServiceRole` we defined in the [Configuring Permissions]({{< ref "030_basic_content/030_basic_experiment/10-permissions" >}}) only grants limited access to SSM so we need to add the the following two policy statements.

```json
        {
            "Sid": "EnableSSMAutomationExecution",
            "Effect": "Allow",
            "Action": [
                "ssm:GetAutomationExecution",
                "ssm:StartAutomationExecution",
                "ssm:StopAutomationExecution"
            ],
            "Resource": "*"
        },
        {
            "Sid": "AllowFisToPassListedRolesToSsm",
            "Effect": "Allow",
            "Action": [
                "iam:PassRole"
            ],
            "Resource": "PLACE_ROLE_ARN_HERE"
        },
```

The first statement allows FIS to use SSM actions. The second statement defines the role that SSM will use. Make sure to insert the ARN of the role you created above.

To update the `FisWorkshopServiceRole`, navigate to the [IAM console](https://console.aws.amazon.com/iam/home#/roles/FisWorkshopServiceRole?section=permissions), select "Roles" on the left, and search for `FisWorkshopServiceRole`.

{{< img "locate-role-policy.en.png" "Locate role policy" >}}

Expand the `FisWorkshopServicePolicy` and select "Edit Policy". Then select the JSON tab and copy the above JSON block just above the first statement `AllowFISExperimentRoleReadOnly`:

{{< img "edit-role-policy.en.png" "Edit fole policy" >}}

Then select "Review policy" and "Save Changes".

{{% notice tip %}}
If the policy editor shows errors, check that you have separated blocks with commas, and that you have updated the Role ARN to a valid value. 
{{% /notice %}}

## Create SSM document

For this section we will replicate the FIS terminate instance action using SSM. Copy the YAML below into a file named `ssm-terminate-instances-asg-az.yaml`

```yaml
---
description: Terminate all instances of ASG in a particular AZ
schemaVersion: '0.3'
assumeRole: "{{ AutomationAssumeRole }}"
parameters:
  AvailabilityZone:
    type: String
    description: "(Required) The Availability Zone to impact"
  AutoscalingGroupName:
    type: String
    description: "(Required) The names of the autoscaling group"
  AutomationAssumeRole:
    type: String
    description: "The ARN of the role that allows Automation to perform
      the actions on your behalf."
mainSteps:
# Find all instances in ASG
- name: DescribeAutoscaling
  action: aws:executeAwsApi
  onFailure: 'step:ExitReview'
  onCancel: 'step:ExitReview'
  timeoutSeconds: 60
  inputs:
    Service: autoscaling
    Api: DescribeAutoScalingGroups
    AutoScalingGroupNames:
        - "{{ AutoscalingGroupName }}"
  outputs:
    - Name: InstanceIds
      Selector: "$..InstanceId"
      Type: StringList
# Find all ASG instances in AZ
- name: DescribeInstances
  action: aws:executeAwsApi
  onFailure: 'step:ExitReview'
  onCancel: 'step:ExitReview'
  timeoutSeconds: 60
  inputs:
    Service: ec2
    Api: DescribeInstances
    Filters:
    - Name: "availability-zone"
      Values:
        - "{{ AvailabilityZone }}"
    - Name: "instance-id"
      Values: "{{ DescribeAutoscaling.InstanceIds }}"
  outputs:
     - Name: InstanceIds
       Selector: "$..InstanceId"
       Type: StringList
# Terminate 100% of selected instances       
- name: TerminateEc2Instances
  action: aws:changeInstanceState
  onFailure: 'step:ExitReview'
  onCancel: 'step:ExitReview'
  inputs:
    InstanceIds: "{{ DescribeInstances.InstanceIds }}"
    DesiredState:  terminated
    Force: true
# Wait for up to 90s to make sure instances have been terminated
- name: VerifyInstanceStateTerminated
  action: aws:waitForAwsResourceProperty
  onFailure: 'step:ExitReview'
  onCancel: 'step:ExitReview'
  timeoutSeconds: 90
  inputs:
    Service: ec2
    Api: DescribeInstanceStatus
    IncludeAllInstances: true
    InstanceIds: "{{ DescribeInstances.InstanceIds }}"
    PropertySelector: "$..InstanceState.Name"
    DesiredValues:
      - terminated
# On normal exit or failure list instances in ASG/AZ
- name: ExitReview
  action: aws:executeAwsApi
  timeoutSeconds: 60
  inputs:
    Service: ec2
    Api: DescribeInstances
    Filters:
    - Name: "availability-zone"
      Values:
        - "{{ AvailabilityZone }}"
    - Name: "instance-id"
      Values: "{{ DescribeAutoscaling.InstanceIds }}"
  outputs:
     - Name: InstanceIds
       Selector: "$..InstanceId"
       Type: StringList
outputs:
- DescribeInstances.InstanceIds
- ExitReview.InstanceIds
```

Use the following CLI command to create the SSM document and export the document ARN:

```bash
SSM_DOCUMENT_NAME=TerminateAsgInstancesWithSsm

# Create SSM document
aws ssm create-document \
  --name ${SSM_DOCUMENT_NAME} \
  --document-format YAML \
  --document-type Automation \
  --content file://ssm-terminate-instances-asg-az.yaml
  
# Construct ARN
REGION=$(aws ec2 describe-availability-zones --output text --query 'AvailabilityZones[0].[RegionName]')
ACCOUNT_ID=$(aws sts get-caller-identity --output text --query 'Account')
DOCUMENT_ARN=arn:aws:ssm:${REGION}:${ACCOUNT_ID}:document/${SSM_DOCUMENT_NAME}
echo $DOCUMENT_ARN
```

## Create FIS Experiment Template

Finally we have to create the FIS experiment template to call the SSM document. Copy the following JSON into a file called `fis-terminate-instances-asg-az.json`. You will need to replace the following:

* DOCUMENT_ARN - use the ARN from the previous step
* AZ_NAME - use the name of your target AZ, e.g. `us-east-1a` if you are working in `us-east-1`
* ASG_NAME - navigate to the [EC2 console](https://console.aws.amazon.com/ec2autoscaling/home?#/details), select the ASG starting with `FisStackAsg`, the copy the full name of the ASG, e.g. `FisStackAsg-ASG46ED3070-1RAQ30VBKLWE1`
* SSM_ROLE_ARN - use the role ARN from the first step of this section. You can also find this by navigating to the [IAM console](https://console.aws.amazon.com/iamv2/home#/roles), searching for `FisWorkshopSsmEc2DemoRole`, clicking on the role and copying the "Role ARN"
* FIS_WORKSHOP_ROLE_ARN - use the role ARN from the second step of this section. You can also find this by navigating to the [IAM console](https://console.aws.amazon.com/iamv2/home#/roles), searching for `FisWorkshopServiceRole`, clicking on the role and copying the "Role ARN"

```json
{
    "description": "Terminate All ASG Instances in AZ",
    "stopConditions": [
        {
            "source": "none"
        }
    ],
    "targets": {
    },
    "actions": {
        "terminateInstances": {
            "actionId": "aws:ssm:start-automation-execution",
            "description": "Terminate Instances in AZ",
            "parameters": {
                "documentArn": "DOCUMENT_ARN",
                "documentParameters": "{\"AvailabilityZone\": \"AZ_NAME\", \"AutoscalingGroupName\": \"ASG_NAME\", \"AutomationAssumeRole\": \"SSM_ROLE_ARN\"}",
                "duration": "PT3M"
            },
            "targets": {
            }
        }
    },
    "roleArn": "FIS_WORKSHOP_ROLE_ARN"
}
```

Once this is done, create the experiment template with this AWS CLI command:

```bash
aws fis create-experiment-template \
   --cli-input-json file://fis-terminate-instances-asg-az.json
```

Note the experiment template ID as we will use this to start the experiment next.

## Run FIS experiment using SSM automation

Using the experiment template ID from the previous step, run the following AWS CLI command to start the experiment:

```bash
aws fis start-experiment \
  --tags Name=DemoSsmAutomationDocument \
  --experiment-template-id TEMPLATE_ID
```

## Troubleshooting

If you run into issues with your FIS experiment failing check the following:

* Experiment fails with "Unable to start SSM automation, not authorized to perform required action" - you probably didn't update your FIS role to enable SSM AutomationExecution and allow PassRole. You can search the "Event history" in the [CloudTrail console](https://console.aws.amazon.com/cloudtrail/home?#/events?EventName=StartAutomationExecution) for "Event name" `StartAutomationExecution`. Note that events can take up to 15min to appear in CloudTrail.

* Experiment fails with "Unable to start SSM automation. A required parameter for the document is missing, or an undefined parameter was provided." - make sure that you properly replaced all the document parameters. You can check this by editing the experiment template. This can also be caused by a role misconfiguration that prevents SSM from assuming the execution role. You can search the "Event history" in the [CloudTrail console](https://console.aws.amazon.com/cloudtrail/home?#/events?EventName=StartAutomationExecution) for "Event name" `StartAutomationExecution`. Note that events can take up to 15min to appear in CloudTrail.

* Experiment fails with "Automation execution completed with status: Failed." - this can be caused by insufficient privileges on the role passed to SSM for execution. This can also happen if there are no instances found in the selected AZ. You can examine the history and output of SSM automation runs by navigating to the [Systems Manager console](https://console.aws.amazon.com/systems-manager/automation/executions) and selecting "Automation" on the left. Then click on the automation run associated with your failed experiment and examine the output of the individual steps for more detail.

* Experiment succeeds but SSM automation status shows "Cancelled" steps. This can happen if you set the "Duration" in the FIS action to be shorter than the time it takes for the SSM document to finish. In this situation FIS will call a "Cancel" action on the SSM document. Ensure that you allow enough time in FIS for the SSM document to finish.
