---
title: "API Failures"
weight: 76
services: true
---


In this section we will cover handling various AWS API errors.  

AWS Fault Injection Service (FIS) introduces the capability to inject failures into AWS API calls by targetting an IAM role and the associated resources that leverage that role for permissions.  

FIS can simulate the following situations:

* API Throttling similar to exceeding service quotas
* Service unavailable 
* Internal Service Errors

{{% notice note %}}
Only [EC2 Service Actions](https://docs.aws.amazon.com/service-authorization/latest/reference/list_amazonec2.html) are supported at this time.  
{{% /notice %}}

For this module we will be deploying an Amazon API Gateway integrated with a Lambda function.  Within the Lambda function, we will be using the DescribeInstances action for the EC2 service API to demonstrate how API failures can impact integrated applications. 



