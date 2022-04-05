---
title: "EC2 spot instances"
chapter: false
weight: 75
services: true
---

In this section we will cover how to validate AWS EC2 Spot Instance Interruption behavior.

[**EC2 Spot Instances**](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-spot-instances.html) make spare EC2 capacity available for steep discounts in exchange for returning them when Amazon EC2 needs the capacity back. Because demand for Spot Instances can vary significantly over time, it is always possible that your Spot Instance might be interrupted. 

To help you gracefully handle interruptions, AWS will send [**Spot Instance Interruption notices**](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/spot-interruptions.html#spot-instance-termination-notices) two minutes before Amazon EC2 stops or terminates your Spot Instance. While it is not always possible to predict demand, AWS may occasionally send an [**EC2 rebalance recommendation**](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/rebalance-recommendations.html) signal before sending the Instance interruption notice.

EC2 Spot instances can be used with Auto Scaling groups or as worker nodes for various forms of batch processing. Because nodes in Auto Scaling groups are usually stateless while batch processes usually generate stateful data we will demonstrate fault injection on a batch compute example with [**checkpointing**](https://en.wikipedia.org/wiki/Application_checkpointing).  

In this section we will use [**AWS Step Functions**](https://docs.aws.amazon.com/step-functions/latest/dg/welcome.html) to orchestrate a hypothetical batch workload:

{{<img "step-functions-runner.en.png" "Step Functions workflow" >}}

The workflow will:

* initialize a workload parameterized with total duration and checkpoint duration
* request a spot instance to run the workload
* wait for the spot instance run to finish
* repeat the request-and-wait cycle until 100% of the job is done

The workload is a python script, passed as [**user data**](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html), that writes metrics to CloudWatch:

{{<img "full-run.en.png" "Full run without interrupt">}}

More details in the next section.

