+++
title = "API Failures"
weight = 76
+++


In this section we will cover handling various AWS API errors.  Amazon Fault Injection Service has the capability to inject several different API error responses by targetting an IAM role and the associated resources that leverage that role for permissions.  These errors include:

* API Throttling due to service quotas
* Service unavailable 
* Internal Service Errors

{{% notice note %}}
Only [EC2 Service Actions]() are supported at this time.  
{{% /notice %}}

For this module we will be deploying an Amazon API Gateway integrated with a lambda function.  Within the lambda function, we will be using the DescribeInstances for the EC2 service API to demonstrate how API failures can impact integrated applications. 



