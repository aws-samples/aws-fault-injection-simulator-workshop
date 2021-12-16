---
title: "Targeting on-prem instances"
weight: 20
draft: false
services: false
---

Some customers use [**AWS Systems Manager for hybrid environments**](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-managedinstances.html) to manage both on-prem and cloud resources and would like to run instance-based fault injection actions against on-prem resources.

In this section we discuss how to use SSM automation (SSMA) to target on-prem instances with the same SSM runbooks used for EC2 instances.

{{% notice warning %}}
Some aspects of using hybrid instances may require activation of "advanced" tier. Please be aware that enabling advanced tier may incur substantial additional [**costs**](https://aws.amazon.com/systems-manager/pricing/#On-Premises_Instance_Management).
{{% /notice %}}

{{% notice note %}}
For this section we assume that you already have a hybrid instance setup. 
{{% /notice %}}

For illustration we will assume that you have a hybrid activation of two on-prem Raspberry Pi instances and the managed instances have been tagged in [**SSM FleetManager**](https://docs.aws.amazon.com/systems-manager/latest/userguide/tagging-managed-instances.html) with tag `OS` / value `Raspbian` and tag `Version` / value `2` and `4` respectively:

{{< img "stresstest-with-runbook-hybrid.png" "Hybrid setup">}}

## Setup

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
# Set required variables
REGION=$(aws ec2 describe-availability-zones --output text --query 'AvailabilityZones[0].[RegionName]')
ACCOUNT_ID=$(aws sts get-caller-identity --output text --query 'Account')

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

* `Filters` - defines the filter parameter for the SSM [**DescribeInstanceInformation**](https://docs.aws.amazon.com/systems-manager/latest/APIReference/API_DescribeInstanceInformation.html) API. By default this is set to `[{"Key":"PingStatus","Values":["Online"]},{"Key":"ResourceType","Values":["ManagedInstance"]}]'`, which will target all running managed instances. Below we will show you how to instead target instances based on FleetManager tags by adding `{"Key":"tag:OS","Values":["Raspbian"]}`.

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
    description: "Parameters to pass to SSM document run on hybrid instances (string to deal with FIS serialization bug)"
  Filters:
    # Normally this would be a MapList. 
    # Currently passing as string and converting to deal with some serialization complexity.
    type: String
    description: '(Optional) Selector JSON for DescribeInstanceInformation as described in CLI/API docs. Default [{"Key":"PingStatus","Values":["Online"]},{"Key":"ResourceType","Values":["ManagedInstance"]}]'
    default: "[{\"Key\":\"PingStatus\",\"Values\":[\"Online\"]},{\"Key\":\"ResourceType\",\"Values\":[\"ManagedInstance\"]}]" 
mainSteps:
# ------------------------------------------------------------------
# Unpack a JSON string to JSON to deal with serialization complexity
- name: FormatConverter
  action: aws:executeScript
  onFailure: 'step:ExitHook'
  onCancel: 'step:ExitHook'
  timeoutSeconds: 60
  inputs:
    Runtime: "python3.6"
    Handler: "script_handler"
    InputPayload: 
      JSONstring: "{{Filters}}"
    Script: |
      import json
      def script_handler(events, context):
          return json.loads(events.get("JSONstring","{}"))
  outputs:
    - Name: Filters
      Selector: "$.Payload"
      Type: MapList
# ------------------------------------------------------------------
# Select managed instances. Note that you can filter EITHER on tags
# OR on instance properties but not both. 
- name: SelectHybridInstances
  action: aws:executeAwsApi
  onFailure: 'step:ExitHook'
  onCancel: 'step:ExitHook'
  timeoutSeconds: 60
  inputs:
    Service: ssm
    Api: DescribeInstanceInformation
    Filters: "{{ FormatConverter.Filters }}"
  outputs:
    - Name: InstanceIds
      Selector: "$..InstanceId"
      Type: StringList
# ------------------------------------------------------------------
# Execute the DocumentName / DocumentParameters from inputs on the 
# instances selected in previous step.
- name: DoStuff
  action: 'aws:runCommand'
  inputs:
    DocumentName: "{{ DocumentName }}"
    InstanceIds:
      - '{{SelectHybridInstances.InstanceIds}}'
    Parameters: "{{ DocumentParameters}}"
# ------------------------------------------------------------------
# NOOP exit point to allow skipping steps if selection fails
- name: ExitHook
  action: aws:sleep
  inputs:
    Duration: PT1S
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

Assuming you have managed instances you can validate the SSM document by invoking it directly like this. 

{{% notice note %}}
Invocation on the command line requires additional square brackets around the individual parameter values independent of the parameter type defined in the SSM document. Complex parameters passed through to SSM documents may additionally require escaping quotes as show below
{{% /notice %}}

```bash
# Select all running managed instances (default with no Filters set)
aws ssm start-automation-execution \
  --document-name "TargetHybridInstances" \
  --parameters '{"AutomationAssumeRole":["'${HYBRID_ROLE_ARN}'"],"DocumentName":["AWSFIS-Run-CPU-Stress"],"DocumentParameters":["{ \"DurationSeconds\": \"120\" }"],"Filters":["[{\"Key\":\"PingStatus\",\"Values\":[\"Online\"]},{\"Key\":\"ResourceType\",\"Values\":[\"ManagedInstance\"]}]"] }'
```

and 

```bash
# Select all instances with tags OS=Raspbian and Version=4
aws ssm start-automation-execution \
  --document-name "TargetHybridInstances" \
  --parameters '{"AutomationAssumeRole":["'${HYBRID_ROLE_ARN}'"],"DocumentName":["AWSFIS-Run-CPU-Stress"],"DocumentParameters":["{ \"DurationSeconds\": \"120\" }"],"Filters":["[{\"Key\":\"tag:OS\",\"Values\":[\"Raspbian\"]},{\"Key\":\"tag:Version\",\"Values\":[\"4\"]}]"] }'

```

Once started you can examine the progress by navigating to the [**SSM Automation console**](https://console.aws.amazon.com/systems-manager/automation/executions) and selecting the execution ID from the invocation.


### Create FIS template

As we saw in the **Create FIS Experiment Template** subsecton of [**FIS SSM Start Automation Setup**]({{< ref "030_basic_content/040_ssm/050_direct_automation" >}}), we need to substitute some ARN values into the FIS template. For convenience and to make the JSON string escaping easier we will do this with some shell substitutions. First we set the relevant environment variables:

```bash
ACCOUNT_ID=$(aws sts get-caller-identity --output text --query 'Account')
REGION=$(aws ec2 describe-availability-zones --output text --query 'AvailabilityZones[0].[RegionName]')

FIS_WORKSHOP_ROLE_ARN=arn:aws:iam::${ACCOUNT_ID}:role/FisWorkshopServiceRole
LINUX_STRESS_ARN=arn:aws:ssm:${REGION}::document/AWSFIS-Run-CPU-Stress

```

Then we use a bash trick to substitute them into our FIS template and write it to disk as `fis-hybrid-target.json`. 

{{% notice note %}}
Because we are doing an additional string evaluation we need to add extra escape characters to the source string leading to the 5 backslashes. See the final FIS template for a more human readable result with one level of escapes removed.
{{% /notice %}}

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
            "description": "Managed instances run-command CPU Stress",
            "parameters": {
                "maxDuration": "PT3M",
                "documentArn": "${HYBRID_DOCUMENT_ARN}",
                "documentParameters": "{ \"AutomationAssumeRole\": \"${HYBRID_ROLE_ARN}\", \"DocumentName\": \"${LINUX_STRESS_ARN}\", \"DocumentParameters\": \"{ \\\\\"DurationSeconds\\\\\": \\\\\"120\\\\\" }\", \"Filters\": \"[ {\\\\\"Key\\\\\":\\\\\"tag:OS\\\\\",\\\\\"Values\\\\\":[\\\\\"Raspbian\\\\\"]} ]\" }"                
            },
            "targets": {
            }
        }
    },
    "roleArn": "${FIS_WORKSHOP_ROLE_ARN}",
    "tags": {
        "Name": "ManagedInstanceCpuStress"
    }
}
EOT

```

Check the template content in `fis-hybrid-target.json` to confirm that the Role and Document ARNs have been filled in, then create the FIS experiment template:

```bash
aws fis create-experiment-template \
   --cli-input-json file://fis-hybrid-target.json

```

## Running experiments

### Targeting all running hybrid instances

SSM allows targeting instances based on properties returned by the SSM [**DescribeInstanceInformation**](https://docs.aws.amazon.com/systems-manager/latest/APIReference/API_DescribeInstanceInformation.html) API. On prem instances are identified by a `ResourceType` of `ManagedInstance`. Additionally we might only want to include currently running instances identified by a `PingStatus` of `Online`.

Navigate to the [**FIS experiment template console**](https://console.aws.amazon.com/fis/home?#ExperimentTemplates), select the experiment template ID created above, and edit the `"Filters"` statement in the `documentParameters` entry:

{{<img "edit-filter-location.png" "Edit filter statement" >}}

to read:

```
"Filters": "[ {\"Key\":\"PingStatus\",\"Values\":[\"Online\"]}, {\"Key\":\"ResourceType\",\"Values\":[\"ManagedInstance\"]} ]"
```

### Targeting specific managed instances

SSM allows you to target instances based on tag values. The default version of the template will target all instances tagged with `OS` value `Raspbian`. We could furter refine that to only target instances with `Version` value `4`.  

Navigate to the [**FIS experiment template console**](https://console.aws.amazon.com/fis/home?#ExperimentTemplates), select the experiment template ID created above, and edit the `"Filters"` statement in the `documentParameters` entry:

{{<img "edit-filter-location.png" "Edit filter statement" >}}

to read:

```
"Filters": "[ {\"Key\":\"tag:OS\",\"Values\":[\"Raspbian\"]}, {\"Key\":\"tag:Version\",\"Values\":[\"4\"]} ]"
```

## Learnings and next steps

The approach outline above provides a generic way to run SSM documents on on-prem managed instances. You may want to expand the SSMA document to suit your needs, e.g. with custom parameters for easier targeting or with more complex selection mechanisms.

### Targeting specific running instances

Because tags are stored separately from instance metadata SSM does not allow joint queries for both metadata such as `PingState` and tags such as `OS`. If you have only a small number of instances you could make two separate lookups and use the `aws:executeScript` action to merge the two result sets. For large numbers of managed instances this is potentially slow and may run into pagination issues on the API. Here we would suggest to instead manage all relevant information in tags and do a single lookup. 

