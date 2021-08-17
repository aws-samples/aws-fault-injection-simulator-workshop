+++
title = "Background"
weight = 10
+++

Before attempting to simulate an AZ failure it's worth considering what we mean by "AZ failure". 

## AZ vs. datacenter

Many of our customers phrase their idea of an AZ failure as "the whole datacenter goes away" but [AWS Availability Zones](https://aws.amazon.com/about-aws/global-infrastructure/regions_az/#Availability_Zones) are "one or more discrete data centers with redundant power, networking, and connectivity in an AWS Region" so even a full "datacenter" outage at AWS may not have the level of impact you would expect on-prem.

## Control plane vs. active infrastructure

An important thing to consider is the difference between the AWS backplane and the provisioned customer infrastructure. A full datacenter outage would create awareness in the AWS control plane that resources are unavailable. In contrast a _simulated_ outage to just the provisioned customer resources has to ensure that only the resources for _a single_ customer are affected.

{{< img "ASG-controlplane.en.png" "Control plane depiction" >}}


For example in the auto scaling setup we built for the **First Experiment** section, we can target EC2 instances in a given AZ for termination by filtering on `Placement.AvailabilityZone`. We _expect_ that the "control plane", in this case the associated Auto Scaling group, will start new instances to replace those terminated. However, since there is no actual AZ failure and the Auto Scaling group thus has no awareness of our experiment, the new instances will most likely be re-created in the AZ for which we wanted to simulate a failure.

## Simulating AZ outage options

In the following sections we will cover how to approximate AZ outages for different configurations and how to build that into a bigger experiment.
