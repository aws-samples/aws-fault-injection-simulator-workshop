---
title: "Cleanup"
chapter: false
weight: 990
---

To ensure you don't incur any further costs after the workshop, please follow these instructions to delete the resources you created:

* Delete the CI/CD pipeline resources created: 
  * Navigate to the [AWS CloudFormation console](https://console.aws.amazon.com/cloudformation/home?#/stacks?filteringStatus=active&filteringText=CicdStack&viewNested=true&hideStacks=false) and find the stack named `CicdStack` 
  * Select the stack 
  * Select "Delete" {{< img "delete-cicd.en.png" >}}
* Following the same procedure as above, delete the following stacks
  * `FisStackRdsAurora`
  * `FisStackLoadGen`
  * `FisStackAsg`
  * `FisStackVpc`

FIS experiment results and custom cloudwatch metrics will be retained so you can refer back to your work.