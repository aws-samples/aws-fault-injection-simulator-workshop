---
title: "Experiment (CLI)"
weight: 30
services: true
---

In this section we will show you how to create an experiment using AWS FIS templates. For clarity, we will replicate the same experiment as we previously did via the AWS console.

## Template overview

[**Experiment templates**](https://docs.aws.amazon.com/fis/latest/userguide/experiment-templates.html) are JSON files containing Actions, Targets, an IAM role, and optional Stop Conditions, and Tags: 

```json
{
    "experimentTemplate": {
        "description": "...",
        "actions": {},
        "targets": {},
        "roleArn": "arn:aws:iam:...",
        "stopConditions": [],
        "logConfiguration": {},
        "tags": {}
    }
}
```

### Actions

[**Actions**](https://docs.aws.amazon.com/fis/latest/userguide/action-sequence.html) specify an action name and `description`, an `actionId` and matching `parameters` picked from the [**AWS FIS Action reference**](https://docs.aws.amazon.com/fis/latest/userguide/fis-actions-reference.html), and a list of `targets` which references the target section in the same template:

```json
"ActionName": {
    "description": "ActionDescription",
    "actionId": "aws:ec2:terminate-instances",
    "parameters": {},
    "targets": {}
}
```

### Targets

[**Targets**](https://docs.aws.amazon.com/fis/latest/userguide/targets.html) specify a name, a `resourceType` from which to select by `resourceArn`, `resourceTags` or `filters`, and `selectionMode` for sampling from the eligible resources by `COUNT()` or `PERCENT()`. 

```json
"TargetGroupName": {
    "resourceType": "aws:ec2:instance",
    "resourceArns": [],
    "resourceTags": {
        "TagName1": "TagValue1",
        "TagName2": "TagValue2",
        ...
    },
    "filters": [
        {
            "path": "State.Name",
            "values": [
                "running"
            ]
        }
    ],
    "selectionMode": "COUNT(1)"
}
```

A note on finding the `path` and `values` for `filters`: as described under ["**Resource filters**"](https://docs.aws.amazon.com/fis/latest/userguide/targets.html#target-identification) in the AWS documentation, filter paths are based on API output. E.g.: if we want to only target running EC2 instances we could use the AWS CLI to list instances:

```bash
aws ec2 describe-instances
```

To find the relevant `path` and `values` start in the `Instances` block of the API output and identify entries you would like to filter on:

```json
{
    "Reservations": [
        {
            "Groups": [],
            "Instances": [
                {
                    "ImageId": "ami-00c36fdebc0d948bd",
                    "InstanceType": "t2.micro",
                    "Placement": {
                        "AvailabilityZone": "us-east-2a",
                        "GroupName": "",
                        "Tenancy": "default"
                    },
                    "State": {
                        "Code": 16,
                        "Name": "running"
                    },
                    "SubnetId": "subnet-0e912694b51e205d6",
                    "VpcId": "vpc-0d4c31ce84606e7eb",
                    "Tags": [
                        {
                            "Key": "Name",
                            "Value": "FisStackAsg/ASG"
                        },
                        ...
                    ],
                    ...
                },
                ...
            ]
        }
    ]
}
```

E.g.: to select an instance that is `running` in `us-east-2a` we would add the following filters:

```json
"filters": [
    {
        "path": "State.Name",
        "values": [
            "running"
        ]
    },
    {
        "path": "Placement.AvailabilityZone",
        "values": [
            "us-east-2a"
        ]
    }
],
```

### Stop conditions

[**Stop conditions**](https://docs.aws.amazon.com/fis/latest/userguide/stop-conditions.html) use a list of Amazon CloudWatch alarms to prematurely stop the experiment if it does not proceed along expected lines:

```json
"stopConditions": [
    {
        "source": "aws:cloudwatch:alarm",
        "value": "arn:aws:cloudwatch:..."
    }
]
```

### Logging configuration

[**Experiment logging**](https://docs.aws.amazon.com/fis/latest/userguide/monitoring-logging.html) can be enabled in the `logConfiguration` section of the template. For logging to CloudWatch similar to the previous section would look like this (with the region and account number filled in appropriately):

```json
"logConfiguration": {
    "cloudWatchLogsConfiguration": {
        "logGroupArn": "arn:aws:logs:YOUR_REGION_HERE:YOUR_ACCOUNT_NUMBER_HERE:log-group:/fis-workshop/fis-logs:*"
    },
    "logSchemaVersion": 1
},
```

### Finished template

Using the above, this would be the finished template. 

{{% notice note %}}
Before using this template, please ensure that you replace the ARN for the FIS execution role on the last line with the ARN of the role you  created in the [**Configuring permissions**]({{< ref "030_basic_content/030_basic_experiment/10-permissions">}}) section and appropriately set the region and account number for the log group ARN.
{{% /notice %}}

```json
{
    "description": "Terminate 50% of instances based on Name Tag",
    "tags": {
        "Name": "FisWorkshop-Exp1-CLI"
    },
    "actions": {
        "FisWorkshopTerminateAsg-1-CLI": {
            "actionId": "aws:ec2:terminate-instances",
            "description": "Terminate 50% of instances based on Name Tag",
            "parameters": {},
            "targets": {
                "Instances": "FisWorkshopAsg-50Percent"
            }
        },
        "Wait": {
            "actionId": "aws:fis:wait",
            "parameters": {
                "duration": "PT3M"
            }
        }
    },
    "targets": {
        "FisWorkshopAsg-50Percent": {
            "resourceType": "aws:ec2:instance",
            "resourceTags": {
                "Name": "FisStackAsg/ASG"
            },
            "selectionMode": "PERCENT(50)"
        }
    },
    "stopConditions": [
        {
            "source": "none"
        }
    ],
    "roleArn": "arn:aws:iam::YOUR_ACCOUNT_NUMBER_HERE:role/FisWorkshopServiceRole",
    "logConfiguration": {
        "cloudWatchLogsConfiguration": {
            "logGroupArn": "arn:aws:logs:YOUR_REGION_HERE:YOUR_ACCOUNT_NUMBER_HERE:log-group:/fis-workshop/fis-logs:*"
        },
        "logSchemaVersion": 1
    },
}
```

## Working with templates

The rest of this section uses the [**AWS CLI**](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html). If you are using [**AWS Cloud9**](https://console.aws.amazon.com/cloud9/home/product) this should work out of the box. Otherwise, please ensure you have installed [**AWS CLI**](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html) and configured [AWS credentials for the CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html#cli-configure-quickstart-config).

### Creating templates

To create an experiment template, copy the above "Finished template" JSON into a file named `fis.json` and ensure you have changed the `roleArn` entry to the ARN of the role you created earlier. To find this role ARN, navigate to the [**IAM Roles**](https://console.aws.amazon.com/iamv2/home#/roles) page, search for the role `FisWorkshopServiceRole`, click on it and copy the value in **Role ARN**. Then, use the CLI to create the template in AWS:

```bash
aws fis create-experiment-template --cli-input-json file://fis.json
```

You should now be able to see the newly created experiment template in the [**AWS Console**](https://console.aws.amazon.com/fis/home?#ExperimentTemplates). 

### Listing templates

This command

```bash
aws fis list-experiment-templates
```

will list all the templates. If you happened to run the `create-experiment-template` command above multiple times you might notice that it is possible to have multiple copies of a template only differentiated by the `id` field. 

While it is possible to update an existing experiment template via the `update-experiment-template` command, and while the content of the template at execution time is saved with the experiment data, this may make it harder to establish what happened during an experiment.

### Exporting / saving templates

Once you have established the `id` of an experiment template you can dump the template. This can be a good way of learning how to write templates as well:

```bash
export EXPERIMENT_TEMPLATE_ID=<YOUR_EXPERIMENT_TEMPLATE_ID_HERE>
aws fis get-experiment-template --id $EXPERIMENT_TEMPLATE_ID
```

You will note that the result is wrapped into an `experimentTemplate: {}` block. You may also notice that there are some additional fields that are not used during experiment template creation. You can generate reusable JSON like so:

```bash
aws fis get-experiment-template --id $EXPERIMENT_TEMPLATE_ID | jq '.experimentTemplate | del( .id) | del(.creationTime) | del(.lastUpdateTime)' 
```

## Validation procedure

Like in the previous section we will be using the AWS CloudWatch dashboard from the previous sections for validation, no additional setup required.

## Run FIS experiment

Like in the previous section we will generate some load:

```bash
# Please ensure that LAMBDA_ARN, URL_HOME, and FIX_CLI_PARAM are still set from previous section

# Run load for 5min, 3x in parallel because max per lambda is 1000
for ii in 1 2 3; do
  aws lambda invoke \
    --function-name ${LAMBDA_ARN} \
    --payload "{
          \"ConnectionTargetUrl\": \"${URL_PHP}\", 
          \"ExperimentDurationSeconds\": 300,
          \"ConnectionsPerSecond\": 1000,
          \"ReportingMilliseconds\": 1000,
          \"ConnectionTimeoutMilliseconds\": 2000,
          \"TlsTimeoutMilliseconds\": 2000,
          \"TotalTimeoutMilliseconds\": 2000
      }" \
    $FIX_CLI_PARAM \
    --invocation-type Event \
    /dev/null
done
```

{{% notice warning %}}
If you are running AWS CLI v2, you need to pass the parameter `--cli-binary-format raw-in-base64-out` or you'll get the error "Invalid base64" when sending the payload.
{{% /notice %}}

Finally we want to run the experiment:

```bash
aws fis start-experiment --experiment-template-id $EXPERIMENT_TEMPLATE_ID --tags Name=FisWorkshopTerminateAsg-1-CLI | jq '.experiment.id'
```

Using the returned `id` field you can check on the outcome of the experiment:

```bash
aws fis get-experiment --id YOUR_EXPERIMENT_ID_HERE
```


## Findings and next steps

The learnings here should be the same as for the console section:

* Carefully choose the resource to affect and how to select them. If we had originally chosen to terminate a single instance (`COUNT`) rather than a fraction (`PERCENT`), we would have severely affected our service.
* Spinning up instances takes time. To achieve resilience, ASGs should be set to have at least two instances running at all times

Additionally, the benefit of using AWS CLI to create and run experiments, is to allow you to document and automate the process for consistency. The best practice is to work with version controlled (e.g. in a Git repository)scripts, as shown here, or CloudFormation templates, as shown in the next section. With that you can setup peer review processes as well as the ability to run experiments continuously via a CI/CD pipeline.

From here you can explore how to set up experiments using [**AWS CloudFormation**]({{< ref "030_basic_content/030_basic_experiment/40-experiment-cfn" >}}) or move on exploring [**more fault types**]({{< ref "030_basic_content/040_ssm" >}}) to inject.
