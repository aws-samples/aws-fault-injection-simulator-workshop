---
title: "Background"
weight: 10
services: true
---

Before attempting to simulate an Availability Zone (AZ) failure it's worth considering what we mean by "AZ failure". 

## AZ vs. data center

Many of our customers phrase their idea of an AZ failure as "the whole data center goes away" but [AWS Availability Zones](https://aws.amazon.com/about-aws/global-infrastructure/regions_az/#Availability_Zones) are "one or more discrete data centers with redundant power, networking, and connectivity in an AWS Region" so even a full "data center" outage at AWS may not have the level of impact you would expect on-prem. Additionally, many AWS services use [cell-based architectures](https://aws.amazon.com/blogs/architecture/shuffle-sharding-massive-and-magical-fault-isolation/) to even further reduce the impact of any system failures.

## Control plane vs. data plane

When simulating AZ failure, an important thing to consider is the difference between the effects of an outage on the "control plane" vs. the "data plane" and their impact on [reliability](https://docs.aws.amazon.com/wellarchitected/latest/reliability-pillar/understanding-availability-needs.html): 

* Data plane is responsible for delivering service. E.g. in an AWS Auto Scaling group, the EC2 instances being started or stopped into different AZs would represent the data plane. Similarly in a user managed cluster there will typically be "worker" nodes that are involved in delivering the service.

* Control plane is used to configure an environment or service. E.g. in AWS Auto Scaling group a scheduler will constantly monitor the requirement for EC2 instances and the number of available instances and will start and stop instances according to requirements. Similarly in a user managed cluster there will typically be "master" or "control" nodes that are involved in monitoring and controlling the worker nodes.

A _real_ outage, whether due to a bad cell, a full data center outage, or even a full AZ outage, would create awareness in the AWS control plane that these resources are unavailable. During the impact period the control plane would only use un-affected parts of the data plane.

In contrast a _simulated_ outage will only affect the data plane, limited to just the provisioned customer resources, without affecting the control plane.

{{< img "ASG-controlplane.en.png" "Control plane depiction" >}}

For example in the auto scaling setup we built for the **First Experiment** section, we can target EC2 instances in a given AZ for termination by filtering on `Placement.AvailabilityZone`. We _expect_ that the "control plane", in this case the associated Auto Scaling group, will start new instances to replace those terminated. However, since there is no actual AZ failure and the Auto Scaling group thus has no awareness of our experiment, the new instances will most likely be re-created in the AZ for which we wanted to simulate a failure.

## Simulating AZ outage options

In the following sections we will cover how to approximate AZ outages for different configurations and how to build that into a bigger experiment in a way that simulates some of the data plane awareness.
