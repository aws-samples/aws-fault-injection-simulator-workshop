---
title: "Cleanup"
chapter: false
weight: 990
---

To ensure you don't incur any further costs after the workshop, please follow these instructions to delete the resources you created.

## Manually

* If you created the CI/CD stack and ran the pipeline, first start by deleting the insfrastructure provisioned by the pipeline: 
  * Navigate to the [AWS CloudFormation console](https://console.aws.amazon.com/cloudformation/home?#/stacks?filteringStatus=active&filteringText=CicdStack&viewNested=true&hideStacks=false) and find the stack named `CicdStack` 
  * Select the stack 
  * Select "Delete" 
* Once, the `CicdStack` is deleted, following the same procedure as above, delete the `CicdStack` stack
  {{< img "delete-cicd.en.png" "Delete stack visual">}}
* Following the same procedure as above, delete the following stacks
  * `FisStackEks`
  * `FisStackEcs`
  * `FisStackRdsAurora`
  * `FisStackLoadGen`
  * `FisStackAsg`
  * `FisStackVpc`

* Delete the CloudWatch log groups:
  * Navigate to the [AWS CloudWatch console](https://console.aws.amazon.com/cloudwatch/home?#logsV2:log-groups$3FlogGroupNameFilter$3Dfis-workshop)
  * Search for `fis-workshop`
  * Select the checkboxes
  * Under "Actions" select "Delete log group(s)"

* Delete Cloud9 Environments
  * Navigate to the [AWS Cloud9 console](https://ap-southeast-1.console.aws.amazon.com/cloud9/home)
  * Delete the Cloud9 environment that you use during the workshop

## Using a script

In your Cloud9 terminal where you performed the **Provision AWS resources** step run the following commands:

```bash
cd ~/environment
```

```bash
cd aws-fault-injection-simulator-workshop
cd resources/templates
./cleanup.sh
```

## Retained resources

CloudWatch metrics and FIS experiments will be retained until the end of their respective expiration periods.

