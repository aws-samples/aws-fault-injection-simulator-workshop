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

Similar to the `aws:ec2:terminate-instances` FIS action, the updated SSM document below will terminate EC2 instances that are members of a specified autoscaling group and are in the selected AZ. Additionally this document will use the Autoscaling API to suspend and re-enable auto-scaling activity: 

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

From here follow the "Create FIS Expereiment Template" step shown in [FIS SSM Start Automation Setup]({{< ref "030_basic_content/040_ssm/050_direct_automation" >}}) to add this as an action to your FIS experiment.

### Workaround: remove AZ from ASG / LB

If you need to model a situation in which EC2 instances in an AZ become unavailable but where the ASG will bring up replacement instances in the remaining AZs, you can modify the ASG to remove subnets associated with the AZ:

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
    description: "(Required) The name of the autoscaling group"
  AutomationAssumeRole:
    type: String
    description: "The ARN of the role that allows Automation to perform
      the actions on your behalf."
  Duration:
    type: String
    description: (Optional) The duration of the attack in minutes (default=5)
    default: '5'
mainSteps:

# ---------------------------------------------------------------
# Query subnets attached to ASG. We will later match these to AZs
# for detaching and re-attaching operations
- name: DescribeAutoscaling
  action: aws:executeAwsApi
  onFailure: 'step:ExitList'
  onCancel: 'step:ExitList'
  timeoutSeconds: 60
  inputs:
    Service: autoscaling
    Api: DescribeAutoScalingGroups
    AutoScalingGroupNames:
        - "{{ AutoscalingGroupName }}"
  outputs:
    - Name: VPCZoneIdentifier
      Selector: "$.AutoScalingGroups[0].VPCZoneIdentifier"
      Type: String
    - Name: AvailabilityZones
      Selector: "$.AutoScalingGroups[0].AvailabilityZones"
      Type: StringList
    - Name: InstanceIds
      Selector: "$..InstanceId"
      Type: StringList

# ---------------------------------------------------------------
# Using ASG information, select subnets / AZs to remove from ASG
# and subnets / AZs to keep in ASG. This also makes an API call
# because the selection logic is more readable than using SSM
# JSONPATH / JMESPATH selectors.
- name: SubnetSelector
  action: aws:executeScript
  onFailure: 'step:ExitList'
  onCancel: 'step:ExitList'
  timeoutSeconds: 60
  inputs:
    Runtime: "python3.6"
    Handler: "script_handler"
    InputPayload: 
      "vpcZoneIdentifier": "{{ DescribeAutoscaling.VPCZoneIdentifier }}"
      "affectAz": "{{ AvailabilityZone }}"
    Script: |
      import boto3
      client = boto3.client("ec2")
      def script_handler(events, context):
          asgSubnets = events.get("vpcZoneIdentifier","").split(",")
          affectAz = events.get("affectAz","")
          botoOut = client.describe_subnets(SubnetIds=asgSubnets).get("Subnets")
          affectSubnets  = [x["SubnetId"] for x in botoOut if x["AvailabilityZone"] == affectAz]
          protectSubnets = [x["SubnetId"] for x in botoOut if x["AvailabilityZone"] != affectAz]
          affectAzs      = [x["AvailabilityZone"] for x in botoOut if x["AvailabilityZone"] == affectAz]
          protectAzs     = [x["AvailabilityZone"] for x in botoOut if x["AvailabilityZone"] != affectAz]
          return { 
              "SubnetIdArray": asgSubnets,
              "AffectSubnetsArray":  affectSubnets,
              "ProtectSubnetsArray": protectSubnets,
              "ProtectVpcZoneIdentifier": ",".join(protectSubnets),
              "AffectAzsArray":      affectAzs,
              "ProtectAzsArray":     protectAzs,
          }
  outputs:
    - Name: SubnetIds
      Selector: "$.Payload.SubnetIdArray"
      Type: StringList
    - Name: AffectSubnetsArray
      Selector: "$.Payload.AffectSubnetsArray"
      Type: StringList
    - Name: ProtectSubnetsArray
      Selector: "$.Payload.ProtectSubnetsArray"
      Type: StringList
    - Name: ProtectVpcZoneIdentifier
      Selector: "$.Payload.ProtectVpcZoneIdentifier"
      Type: String
    - Name: AffectAzsArray
      Selector: "$.Payload.AffectAzsArray"
      Type: StringList
    - Name: ProtectAzsArray
      Selector: "$.Payload.ProtectAzsArray"
      Type: StringList

# ---------------------------------------------------------------
# Remove subnets / AZs
- name: RemoveSubnets
  action: aws:executeAwsApi
  onFailure: 'step:Rollback'
  onCancel: 'step:Rollback'
  inputs:
    Service: autoscaling
    Api: UpdateAutoScalingGroup
    AutoScalingGroupName: "{{ AutoscalingGroupName }}"
    VPCZoneIdentifier: "{{ SubnetSelector.ProtectVpcZoneIdentifier }}"

# ---------------------------------------------------------------
# Wait in outage simulation state
- name: WaitForDuration
  action: 'aws:sleep'
  onFailure: 'step:Rollback'
  onCancel: 'step:Rollback'
  inputs:
    Duration: 'PT{{Duration}}M'

# ---------------------------------------------------------------
# Reset ASG subnets / AZs to original state before we started. 
- name: Rollback
  action: aws:executeAwsApi
  onFailure: 'step:ExitList'
  onCancel: 'step:ExitList'
  inputs:
    Service: autoscaling
    Api: UpdateAutoScalingGroup
    AutoScalingGroupName: "{{ AutoscalingGroupName }}"
    VPCZoneIdentifier: "{{ DescribeAutoscaling.VPCZoneIdentifier }}"

# ---------------------------------------------------------------
# List state of ASG after all is done. Hopefully it's the same as
# before we started. 
- name: ExitList
  action: aws:executeAwsApi
  timeoutSeconds: 60
  inputs:
    Service: autoscaling
    Api: DescribeAutoScalingGroups
    AutoScalingGroupNames:
        - "{{ AutoscalingGroupName }}"
  outputs:
    - Name: VPCZoneIdentifier
      Selector: "$.AutoScalingGroups[0].VPCZoneIdentifier"
      Type: String
    - Name: AvailabilityZones
      Selector: "$.AutoScalingGroups[0].AvailabilityZones"
      Type: StringList
    - Name: InstanceIds
      Selector: "$..InstanceId"
      Type: StringList
  isEnd: true

outputs:
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

From here follow the "Create FIS Expereiment Template" step shown in [FIS SSM Start Automation Setup]({{< ref "030_basic_content/040_ssm/050_direct_automation" >}}) to add this as an action to your FIS experiment.

Note that the above SSM document example limits itself to affecting the ASG and relying on the ASG to _cleanly_ drain and remove instances from the LB. You can add extra steps to explicitly terminate instances and/or add NACLs to achieve more extreme failure scenarios on your instances.


### Avoid: NACLs and SGs on their own

For EC2 instances in ASGs avoid the _exclusive_ use Network Access Control Lists (NACLs) or security groups (SGs) as they will create untypical failure scenarios. In particular NACLs preventing access to an ASG or LB subnet will lead to churn when the ASG tries to spin up new instances and they fail to register as healthy. 

If other aspects of your simulation require using NACLs or SGs we suggest combining them with the prevention autoscaling actions as described in the first workaround section above and/or with the removal of subnets from the ASG as shown in the second example.
