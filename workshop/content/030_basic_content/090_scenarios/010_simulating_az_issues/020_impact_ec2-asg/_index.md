+++
title = "Impact EC2/ASG"
weight = 20
draft = true
+++


This section covers approaches to testing AZ issues for EC2 instances and autoscaling groups.

## Standalone EC2

Standalone EC2 instances can be directly targeted based on avaliability zone placement using the target filter and set `Placement.AvailabilityZone` to the desired availability zone.

## EC2 with autoscaling

As mentioned above, autoscaling groups (ASGs) will try to rebalance instances and will likely create new instances in the "affected" AZ. Workarounds for this, using custom SSM documents, include:

* temporarily [suspend ASG](https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-suspend-resume-processes.html) scaling / rebalancing - this helps measure the immediate impact of an AZ failure but does not simulate healing / rebalancing that would happen in an actual outage.
* remove an AZ from the ASG / LB 
* ...

Approaches to avoid:

* do not modify Network Access Control Lists (NACLs) or security groups (SGs) as this will lead to churn when the ASG tries to spin up new instances and they fail to register as healthy.
