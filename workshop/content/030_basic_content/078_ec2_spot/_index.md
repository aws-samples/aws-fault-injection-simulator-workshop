---
title: "EC2 spot instances"
chapter: false
weight: 75
services: true
draft: true
---

In this section we will cover how to validate EC2 Spot Instance Interruption behavior.

[**EC2 Spot Instances**](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-spot-instances.html) make spare EC2 capacity available for steep discounts in exchange for returning them when Amazon EC2 needs the capacity back. Because demand for Spot Instances can vary significantly over time, it is always possible that your Spot Instance might be interrupted. 

To help you gracefully handle interruptions, AWS will send [**Spot Instance Interruption notices**](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/spot-interruptions.html#spot-instance-termination-notices) two minutes before Amazon EC2 stops or terminates your Spot Instance. While it is not always possible to predict demand, AWS may occasionally send an [**EC2 rebalance recommendation**](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/rebalance-recommendations.html) signal before sending the Instance interruption notice.

