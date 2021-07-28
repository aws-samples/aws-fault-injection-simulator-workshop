---
title: "Cleanup"
chapter: false
weight: 990
---

To ensure you don't incur any further costs after the workshop, please follow these instructions to delete the resources you created.

## Manually

* Delete the CI/CD pipeline resources created: 
  * Navigate to the [AWS CloudFormation console](https://console.aws.amazon.com/cloudformation/home?#/stacks?filteringStatus=active&filteringText=CicdStack&viewNested=true&hideStacks=false) and find the stack named `CicdStack` 
  * Select the stack 
  * Select "Delete" 
  {{< img "delete-cicd.en.png" "Delete stack visual">}}
* If you created the `CpuStress` stack in the **AWS Systems Manager Integration** section, delete it follwing the same procedure.
* Following the same procedure as above, delete the following stacks
  * `FisStackRdsAurora`
  * `FisStackLoadGen`
  * `FisStackAsg`
  * `FisStackVpc`

* Delete the CloudWatch log groups:
  * Navigate to the [AWS CloudWatch console](https://console.aws.amazon.com/cloudwatch/home?#logsV2:log-groups$3FlogGroupNameFilter$3Dfis-workshop)
  * Search for `fis-workshop`
  * Select the checkboxes
  * Under "Actions" select "Delete log group(s)"

## Using a script

On the same machine where you performed the **Provision AWS resources** step run the following commans:

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

