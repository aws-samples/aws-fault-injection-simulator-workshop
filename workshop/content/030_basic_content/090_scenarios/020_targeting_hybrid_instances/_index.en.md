---
title: "Targeting on-prem instances"
weight: 20
draft: true
services: false
---

Some customers use [**AWS Systems Manager for hybrid environments**](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-managedinstances.html) to manage both on-prem and cloud resources and would like to run instance-based fault injection actions against on-prem resources.

In this section we discuss how to use SSM automation to target on-prem instances with the same SSM runbooks used for EC2 instances.

{{% notice warning %}}
Some aspects of using hybrid instances may require activation of "advanced" tier. Please be aware that enabling advanced tier may incur substantial additional [**costs**](https://aws.amazon.com/systems-manager/pricing/#On-Premises_Instance_Management).
{{% /notice %}}

{{% notice note %}}
For this section we assume that you already have a hybrid instance setup. 
{{% /notice %}}

For illustration we will assume that you have a hybrid activation of an on-prem Raspberry Pi and the managed instance has been tagged in [**SSM FleetManager**](https://docs.aws.amazon.com/systems-manager/latest/userguide/tagging-managed-instances.html) with tag `OS` / value `Raspbian` and tag `Version` / value `4`:

{{< img "stresstest-with-runbook-hybrid.png" "Hybrid setup">}}

To replicate the [**Linux CPU Stress Experiment**]({{< ref "030_basic_content/040_ssm/020_linux_stress" >}}) on the on-prem instance we will use a variation on the [**FIS SSM Start Automation Setup**]({{< ref "030_basic_content/040_ssm/050_direct_automation" >}}).

### Create SSM role

First we will need an SSM execution role to enable running the on-prem automation:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "EnableAsgDocument",
            "Effect": "Allow",
            "Action": [
                "ssm:DescribeInstanceInformation",
                "ssm:ListCommands",
                "ssm:ListCommandInvocations",
                "ssm:SendCommand"            ],
            "Resource": "*"
        }
    ]
}
```

with an SSM assume role trust policy:

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

To create a role, save the two JSON blocks above into files named `iam-hybrid-demo-policy.json` and `iam-hybrid-demo-trust.json` and run the following CLI commands to create a role named `FisWorkshopSsmHybridDemoRole`:

```bash
cd ~/environment/aws-fault-injection-simulator-workshop
cd workshop/content/030_basic_content/090_scenarios/020_targeting_hybrid_instances

HYBRID_ROLE_NAME=FisWorkshopSsmHybridDemoRole

aws iam create-role \
  --role-name ${HYBRID_ROLE_NAME} \
  --assume-role-policy-document file://iam-hybrid-demo-trust.json

aws iam put-role-policy \
  --role-name ${HYBRID_ROLE_NAME} \
  --policy-name ${HYBRID_ROLE_NAME} \
  --policy-document file://iam-hybrid-demo-policy.json

# Export ARN for later
HYBRID_ROLE_ARN=arn:aws:iam::${ACCOUNT_ID}:role/${HYBRID_ROLE_NAME}
echo ${HYBRID_ROLE_ARN}
```

### Update FIS service role

Update the `FisWorkshopServiceRole` as described in the [**FIS SSM Start Automation Setup**]({{< ref "030_basic_content/040_ssm/050_direct_automation" >}}) section, using the role ARN from the statement above. If you had previously performed that update note that you can add multiple role ARNs so the resulting `AllowFisToPassListedRolesToSsm` "Sid" would look like this:

```json
{
            "Sid": "AllowFisToPassListedRolesToSsm",
            "Effect": "Allow",
            "Action": [
                "iam:PassRole"
            ],
            "Resource": [
                "PREVIOUS_ROLE_ARN_HERE",
                "PLACE_NEW_ROLE_ARN_HERE"
            ]
        }
```

### Create SSM document

The core of this approach is to select managed instances targets using SSM and then execute runbooks against the selected instances. The following parameters help target instances and define the fault injection to run:

* `Filters` - defines the filter parameter for the SSM [**DescribeInstanceInformation**](https://docs.aws.amazon.com/systems-manager/latest/APIReference/API_DescribeInstanceInformation.html) API. By default this is set to `[{"Key":"PingStatus","Values":["Online"]},{"Key":"ResourceType","Values":["ManagedInstance"]}]'`, which will target all running managed instances. Below we will show you how to target instances based on FleetManager tags by adding `{"Key":"tag:OS","Values":["Raspbian"]}`.

* `DocumentName` - the name of an SSM runbook document to be called from this automation document after instance selection.

* `DocumentParameters` - Parameters to pass to the document. In our example below this will be the stress duration.

```yaml
---
description: Run SSM command on SSM hybrid instances
schemaVersion: '0.3'
assumeRole: "{{ AutomationAssumeRole }}"
parameters:
  AutomationAssumeRole:
    type: String
    description: "The ARN of the role that allows Automation to perform
      the actions on your behalf."
  DocumentName:
    type: String
    description: "SSM document name to run on hybrid instances"
  DocumentParameters:
    type: StringMap
    description: "Parameters to pass to SSM document run on hybrid instances"
  Filters:
    type: MapList
    description: '(Optional) Selector JSON for DescribeInstanceInformation as described in CLI/API docs. Default [{"Key":"PingStatus","Values":["Online"]},{"Key":"ResourceType","Values":["ManagedInstance"]}]'
    default: 
      - Key: PingStatus
        Values:
          - Online
      - Key: ResourceType
        Values:
          - ManagedInstance
mainSteps:
- name: SelectHybridInstances
  action: aws:executeAwsApi
  timeoutSeconds: 60
  inputs:
    Service: ssm
    Api: DescribeInstanceInformation
    Filters: "{{ Filters }}"
  outputs:
    - Name: InstanceIds
      Selector: "$..InstanceId"
      Type: StringList
- name: DoStuff
  action: 'aws:runCommand'
  inputs:
    DocumentName: "{{ DocumentName }}"
    InstanceIds:
      - '{{SelectHybridInstances.InstanceIds}}'
    Parameters: "{{ DocumentParameters}}"
outputs:
- SelectHybridInstances.InstanceIds

```

Use the following CLI command to create the SSM document and export the document ARN:

```bash
cd ~/environment/aws-fault-injection-simulator-workshop
cd workshop/content/030_basic_content/090_scenarios/020_targeting_hybrid_instances

HYBRID_DOCUMENT_NAME=TargetHybridInstances

# Create SSM document
aws ssm create-document \
  --name ${HYBRID_DOCUMENT_NAME} \
  --document-format YAML \
  --document-type Automation \
  --content file://hybrid-target.yaml
  
# Construct ARN
REGION=$(aws ec2 describe-availability-zones --output text --query 'AvailabilityZones[0].[RegionName]')
ACCOUNT_ID=$(aws sts get-caller-identity --output text --query 'Account')
HYBRID_DOCUMENT_ARN=arn:aws:ssm:${REGION}:${ACCOUNT_ID}:document/${HYBRID_DOCUMENT_NAME}
echo $HYBRID_DOCUMENT_ARN
```

### Create FIS template

```bash
REGION=$(aws ec2 describe-availability-zones --output text --query 'AvailabilityZones[0].[RegionName]')

FIS_WORKSHOP_ROLE_ARN=arn:aws:iam::${ACCOUNT_ID}:role/FisWorkshopServiceRole
LINUX_STRESS_ARN=arn:aws:ssm:${REGION}::document/AWSFIS-Run-CPU-Stress

```

```bash
cat > fis-hybrid-target.json <<EOT
{
    "description": "Run stress on managed instance",
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
                "maxDuration": "PT3M",
                "documentArn": "${HYBRID_DOCUMENT_ARN}",
                "documentParameters": "{ \"AutomationAssumeRole\": \"${HYBRID_ROLE_ARN}\", \"DocumentName\": \"${LINUX_STRESS_ARN}\", \"DocumentParameters\": \"{ \\\\\"DurationSeconds\\\\\": \\\\\"120\\\\\" }\", \"Filters\": \"[ {\\\\\"Key\\\\\":\\\\\"tag:OS\\\\\",\\\\\"Values\\\\\":[\\\\\"Raspbian\\\\\"]} ]\" }"                
            },
            "targets": {
            }
        }
    },
    "roleArn": "${FIS_WORKSHOP_ROLE_ARN}"
}
EOT

```

arn:${AWS::Partition}:ssm:${AWS::Region}:${AWS::AccountId}:document/${WinStressDocument}


'{"AutomationAssumeRole":["arn:aws:iam::238810465798:role/FisWorkshopSsmHybridDemoRole"],"DocumentName":["AWSFIS-Run-CPU-Stress"],"DocumentParameters":["{ \"DurationSeconds\": \"120\" }"],"Filters":["{\"Key\":\"PingStatus\",\"Values\":[\"Online\"]}","{\"Key\":\"ResourceType\",\"Values\":[\"ManagedInstance\"]}","{\"Key\":\"tag:OS\",\"Values\":[\"Raspbian\"]}"]}'


Check the template content in `fis-hybrid-target.json` to confirm that the Role and Document ARNs have been filled in, then create the FIS experiment template

```bash
aws fis create-experiment-template \
   --cli-input-json file://fis-hybrid-target.json

```


```bash
aws ssm create-document \
    --name ${HYBRID_DOCUMENT_NAME} \
    --document-format YAML \
    --document-type Automation \
    --content file://hybrid-target.yaml 

aws ssm update-document \
    --name ${HYBRID_DOCUMENT_NAME} \
    --document-format YAML \
    --content file://hybrid-target.yaml \
    --document-version '$LATEST'

```

```
[ 
    { "Key": "PingStatus", "Values": [ "Online" ] },
    { "Key": "ResourceType", "Values": [ "ManagedInstance" ] },
    {"Key":"tag:OS","Values":["Raspbian"]}
]
```

```bash
aws ssm start-automation-execution \
  --document-name ${HYBRID_DOCUMENT_NAME} \
  --parameters "AutomationAssumeRole=arn:aws:iam::238810465798:role/FisWorkshopSsmEc2DemoRole,DocumentName=AWSFIS-Run-CPU-Stress,DocumentParameters='{ \"DurationSeconds\": \"120\" }'"

aws ssm start-automation-execution \
  --document-name ${HYBRID_DOCUMENT_NAME} \
  --parameters "AutomationAssumeRole=arn:aws:iam::238810465798:role/FisWorkshopSsmEc2DemoRole,DocumentName=AWSFIS-Run-CPU-Stress,DocumentParameters='{ \"DurationSeconds\": \"120\",\"Filters\": [ { \"Key\": \"PingStatus\", \"Values\": [ \"Online\" ] }, { \"Key\": \"ResourceType\", \"Values\": [ \"ManagedInstance\" ] }, {\"Key\":\"tag:OS\",\"Values\":[\"Raspbian\"]} ] }'"

```

```bash
# This fails because of linked filters
aws ssm start-automation-execution \
  --document-name "TargetHybridInstances" \
  --document-version "\$DEFAULT" \
  --parameters '{"AutomationAssumeRole":["arn:aws:iam::238810465798:role/FisWorkshopSsmHybridDemoRole"],"DocumentName":["AWSFIS-Run-CPU-Stress"],"DocumentParameters":["{ \"DurationSeconds\": \"120\" }"],"Filters":["{\"Key\":\"PingStatus\",\"Values\":[\"Online\"]}","{\"Key\":\"ResourceType\",\"Values\":[\"ManagedInstance\"]}","{\"Key\":\"tag:OS\",\"Values\":[\"Raspbian\"]}"]}' \
  --region us-west-2
```

```bash
# This works
aws ssm start-automation-execution \
  --document-name "TargetHybridInstances" \
  --document-version "\$DEFAULT" \
  --parameters '{"AutomationAssumeRole":["arn:aws:iam::238810465798:role/FisWorkshopSsmHybridDemoRole"],"DocumentName":["AWSFIS-Run-CPU-Stress"],"DocumentParameters":["{ \"DurationSeconds\": \"120\" }"],"Filters":["{\"Key\":\"tag:OS\",\"Values\":[\"Raspbian\"]}"]}' \
  --region us-west-2
```

```bash
# This works
aws ssm start-automation-execution \
  --document-name "TargetHybridInstances" \
  --document-version "\$DEFAULT" \
  --parameters '{"AutomationAssumeRole":["arn:aws:iam::238810465798:role/FisWorkshopSsmHybridDemoRole"],"DocumentName":["AWSFIS-Run-CPU-Stress"],"DocumentParameters":["{ \"DurationSeconds\": \"120\" }"],"Filters":["{\"Key\":\"PingStatus\",\"Values\":[\"Online\"]}","{\"Key\":\"ResourceType\",\"Values\":[\"ManagedInstance\"]}"]}' \
  --region us-west-2
```

---

```bash
aws ssm create-document \
    --name ${HYBRID_DOCUMENT_NAME}-converted \
    --document-format YAML \
    --document-type Automation \
    --content file://hybrid-target-stringconverter.yaml 

aws ssm start-automation-execution \
  --document-name ${HYBRID_DOCUMENT_NAME}-converted \
  --document-version "\$DEFAULT" \
  --parameters '{"AutomationAssumeRole":["arn:aws:iam::238810465798:role/FisWorkshopSsmHybridDemoRole"],"DocumentName":["AWSFIS-Run-CPU-Stress"],"DocumentParameters":["{ \"DurationSeconds\": \"120\" }"],"Filters":["[{\"Key\":\"tag:OS\",\"Values\":[\"Raspbian\"]}]"]}' \
  --region us-west-2

```