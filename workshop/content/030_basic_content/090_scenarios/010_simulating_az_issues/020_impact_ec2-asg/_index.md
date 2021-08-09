+++
title = "Impact EC2/ASG"
weight = 20
draft = true
+++


This section covers approaches to simulating AZ issues for EC2 instances and autoscaling groups. 

{{% notice warning %}}
This section relies on the use of SSM Automation documents. Please review the [FIS SSM Start Automation Setup]({{< ref "030_basic_content/040_ssm/050_direct_automation" >}}) when you need additional details.
{{% /notice %}}

## Standalone EC2

Standalone EC2 instances can be directly targeted based on avaliability zone placement using the target filter and set `Placement.AvailabilityZone` to the desired availability zone.

## EC2 with autoscaling

We can use `Placement.AvailabilityZone` to target instances that are part of an autoscaling grouop as well. However, as mentioned in the [background]({{< ref "010_background" >}}) section, autoscaling groups (ASGs) will try to rebalance instances and will likely create new instances in the "affected" AZ. 

### Workaround: prevent autoscaling

If you only need to verify continued availability you can instruct to ASG to [suspend activity](https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-suspend-resume-processes.html) and not add any new instances.  

For this we can extend the SSM Automation approach shown in [FIS SSM Start Automation Setup]({{< ref "030_basic_content/040_ssm/050_direct_automation" >}}).

Similar to the `aws:ec2:terminate-instances` FIS action, the updated document below will terminate EC2 instances that are members of a specified autoscaling group and are in the selected AZ. Additionally this document will use the Autoscaling API to suspend and re-enable auto-scaling activity: 

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
  Duration:
    type: String
    description: (Optional) The duration of the attack in minutes (default=5)
    default: '5'
mainSteps:
# Find all instances in ASG
- name: DescribeAutoscaling
  action: aws:executeAwsApi
  onFailure: 'step:Rollback'
  onCancel: 'step:Rollback'
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
  onFailure: 'step:Rollback'
  onCancel: 'step:Rollback'
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
# Suspend ASG activity to prevent scaling
- name: SuspendAsgProcesses
  action: aws:executeAwsApi
  onFailure: 'step:Rollback'
  onCancel: 'step:Rollback'
  inputs:
    Service: autoscaling
    Api: SuspendProcesses
    AutoScalingGroupName: "{{ AutoscalingGroupName }}"
    ScalingProcesses: ['Launch','Terminate']
# Terminate 100% of selected instances
- name: TerminateEc2Instances
  action: aws:changeInstanceState
  onFailure: 'step:Rollback'
  onCancel: 'step:Rollback'
  inputs:
    InstanceIds: "{{ DescribeInstances.InstanceIds }}"
    DesiredState:  terminated
    Force: true
# Wait for up to 90s to make sure instances have been terminated
- name: VerifyInstanceStateTerminated
  action: aws:waitForAwsResourceProperty
  onFailure: 'step:Rollback'
  onCancel: 'step:Rollback'
  timeoutSeconds: 90
  inputs:
    Service: ec2
    Api: DescribeInstanceStatus
    IncludeAllInstances: true
    InstanceIds: "{{ DescribeInstances.InstanceIds }}"
    PropertySelector: "$..InstanceState.Name"
    DesiredValues:
      - terminated
# Wait for duration specified before re-enabling autoscaling
# Note that this is different of the FIS duration setting, 
# make sure that FIS duration setting is higher than this
- name: WaitForDuration
  action: 'aws:sleep'
  onFailure: 'step:Rollback'
  onCancel: 'step:Rollback'
  inputs:
    Duration: 'PT{{Duration}}M'
# Always re-enable autoscaling
- name: Rollback
  action: aws:executeAwsApi
  inputs:
    Service: autoscaling
    Api: ResumeProcesses
    AutoScalingGroupName: "{{ AutoscalingGroupName }}"
    ScalingProcesses: ['Launch','Terminate']
  isEnd: true
outputs:
- DescribeInstances.InstanceIds
```

This SSM document requires an SSM role with the following permissions:

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

### Workaround: remove AZ from ASG / LB

... work in progress ... 


### Avoid: NACLs and SGs

For EC2 instances in ASGs avoid using Network Access Control Lists (NACLs) or security groups (SGs) as this will lead to churn when the ASG tries to spin up new instances and they fail to register as healthy. If other aspects of your simulation require using NACLs or SGs ensure you prevent autoscaling actions as described in the first workaround section above.
