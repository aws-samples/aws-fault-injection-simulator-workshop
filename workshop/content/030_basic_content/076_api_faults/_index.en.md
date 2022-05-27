---
title: "API Failures"
weight: 76
services: true
---

Cloud infrastructure is controlled by “control plane” APIs. These APIs can be used to query existing infrastructure, e.g. to list all the EC2 instances running in a region. These APIs can also be used to create new infrastructure or modify infrastructure configurations, e.g. an autoscaling group adding or removing instances in response to load.

AWS achieves very high availability for control plane APIs but as Dr. Werner Vogels reminds us "Everything fails all the time" and our code needs to engineer for resilience against possible failures. In order to ensure that our resilience measures are effective, AWS Fault Injection Service (FIS) allows simulating failures by narrowly targeting individual execution roles. For this module we will be deploying an Amazon API Gateway integrated with a Lambda function.  Within the Lambda function, we will be using the DescribeInstances action for the EC2 service API to demonstrate how API failures can impact integrated applications. 

{{< img "ApiFailures.png" "Api failure infrastructure" >}}

FIS provides three error scenarios:

* API is partially unavailable (intermittent failures due to throttling)
* API is fully unavailable (all API calls fail)
* API returns an error message on invocation

In this section we will demonstrate API throttling and unavailability by using 
FIS to to inject failures into AWS API calls by targeting an IAM role and the associated resources that leverage that role for permissions.  

{{% notice note %}}
Only [EC2 Service Actions](https://docs.aws.amazon.com/service-authorization/latest/reference/list_amazonec2.html) are supported at this time.  
{{% /notice %}}




