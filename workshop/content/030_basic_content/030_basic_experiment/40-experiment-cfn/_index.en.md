---
title: "Experiment (CloudFormation)"
weight: 40
services: true
---

In this section we will cover how to define and update experiment templates using [CloudFormation](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-fis-experimenttemplate.html).

## CFN template format

The AWS CloudFormation template uses the same format as the API but capitalizes the first letter of section names. As such the AWS FIS experiment template from the previous section would become:

```json
{
"Type" : "AWS::FIS::ExperimentTemplate",
"Properties" : {
    "Description": "Terminate 50% of instances based on Name Tag",
    "Tags": {
        "Name": "FisWorkshop-Exp1-CFN-v1.0.0"
    },
    "Actions": {
        "FisWorkshopTerminateAsg-1-CFN": {
            "ActionId": "aws:ec2:terminate-instances",
            "Description": "Terminate 50% of instances based on Name Tag",
            "Parameters": {},
            "Targets": {
                "Instances": "FisWorkshopAsg-50Percent"
            }
        },
        "Wait": {
            "ActionId": "aws:fis:wait",
            "Parameters": {
                "duration": "PT3M"
            }
        }
    },
    "Targets": {
        "FisWorkshopAsg-50Percent": {
            "ResourceType": "aws:ec2:instance",
            "ResourceTags": {
                "Name": "FisStackAsg/ASG"
            },
            "SelectionMode": "PERCENT(50)"
        }
    },
    "StopConditions": [
        {
            "Source": "none"
        }
    ],
    "RoleArn": {
        "Fn::Sub": "arn:aws:iam::YOUR_ACCOUNT_ID:role/FisWorkshopServiceRole"
    }
}
```

We can wrap this into the `Resources` section of a [**CloudFormation template**](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/gettingstarted.templatebasics.html#gettingstarted.templatebasics.multiple). Additionally CloudFormation allows us to use [**pseudo parameters**](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/pseudo-parameter-reference.html#cfn-pseudo-param-accountid) which we can use to automatically insert the account number into the role definition using the `AWS::AccountId` and `AWS::Region` parameters in conjunction with the [`Fn::Sub`](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/intrinsic-function-reference-sub.html) function. Thus, a simple CFN template would become:

```json
{
    "Resources" : {
        "FisExperimentDemo" : {
            "Type" : "AWS::FIS::ExperimentTemplate",
            "Properties" : {
                "Description": "Terminate 50% of instances based on Name Tag",
                "Tags": {
                    "Name": "FisWorkshop-Exp1-CFN-v1.0.0"
                },
                "Actions": {
                    "FisWorkshopTerminateAsg-1-CFN": {
                        "ActionId": "aws:ec2:terminate-instances",
                        "Description": "Terminate 50% of instances based on Name Tag",
                        "Parameters": {},
                        "Targets": {
                            "Instances": "FisWorkshopAsg-50Percent"
                        }
                    },
                    "Wait": {
                        "ActionId": "aws:fis:wait",
                        "Parameters": {
                            "duration": "PT3M"
                        }
                    }
                },
                "Targets": {
                    "FisWorkshopAsg-50Percent": {
                        "ResourceType": "aws:ec2:instance",
                        "ResourceTags": {
                            "Name": "FisStackAsg/ASG"
                        },
                        "SelectionMode": "PERCENT(50)"
                    }
                },
                "StopConditions": [
                    {
                        "Source": "none"
                    }
                ],
                "RoleArn": {
                    "Fn::Sub": "arn:aws:iam::${AWS::AccountId}:role/FisWorkshopServiceRole"
                },
                "LogConfiguration": {
                    "CloudWatchLogsConfiguration": {
                        "LogGroupArn": {
                            "Fn::Sub": "arn:aws:logs:${AWS::Region}:${AWS::AccountId}:log-group:/fis-workshop/fis-logs:*"
                        }
                    },
                    "LogSchemaVersion": 1
                }
            }
        }
    }
}
```

## Using the CFN template

A deep dive into [**AWS CloudFormation**](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/Welcome.html) is beyond the scope of this workshop, so we will only cover how to create and update stacks via the CLI.

### Create a new template / experiment

To create a stack, and thus the contained FIS experiment template, copy the above JSON into a file named `cfn-fis-experiment.json` then run this AWS CLI command:

```bash
aws cloudformation create-stack --stack-name FisWorkshopExperimentTemplate --template-body file://cfn-fis-experiment.json
```

If you navigate to the [**CloudFormation console**](https://console.aws.amazon.com/cloudformation/home?#/stacks?filteringStatus=active&filteringText=FisWorkshopExperiment&viewNested=true&hideStacks=false) you should now see a new stack named `FisWorkshopExperimentTemplate` and navigating to the [**FIS console**](https://console.aws.amazon.com/fis/home?#ExperimentTemplates) should show an experiment named `FisWorkshop-Exp1-CFN-v1.0.0`

### Update template / experiment

To update the experiment template you will need to update the CFN template. Let's change the `Name` tag from `FisWorkshop-Exp1-CFN-v1.0.0` to `FisWorkshop-Exp1-CFN-v2.0.0` and save the file.

Then run the AWS CLI command:

```bash
aws cloudformation update-stack --stack-name FisWorkshopExperimentTemplate --template-body file://cfn-fis-experiment.json
```

This should update the name of your experiment template in the FIS console. Obviously this is most useful if you make actual changes to the template itself too.

## Validation and running FIS experiment

The steps so far created an experiment template to run an experiment and validate outcomes you can follow the procedures outlined in the previous [**Experiment (Console)**]({{< ref "030_basic_content/030_basic_experiment/20-experiment-console" >}}) or [**Experiment (CLI)**]({{< ref "030_basic_content/030_basic_experiment/30-experiment-cli" >}}) sections.

## Findings and next steps

The learnings here should be the same as for the console section:

* Carefully choose the resource to affect and how to select them. If we had originally chosen to terminate a single instance (`COUNT`) rather than a fraction (`PERCENT`), we would have severely affected our service.
* Spinning up instances takes time. To achieve resilience, ASGs should be set to have at least two instances running at all times

As mentioned in the previous section, it is valuable to version control the contents of experiment templates for consistency and automation by using AWS CLI scripting. Using CloudFormation goes one step further and allows you to version control the creation of experiment templates in addition to the template content.

In the next section we will explore more fault injection options.
