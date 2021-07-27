+++
title = "Simulating AZ Issues"
date =  2021-04-14T17:24:41-06:00
weight = 10
+++

A common ask we hear is for "AZ outage" simulation. Because AWS has spent more than a decade working to _prevent_ exactly those scenarios and to self-heal any disruption, there is currently no easy button solution to simulate this. In the meantime, this section will cover options for approximating AZ failures.

## Control plane vs. active infrastructure

Before attempting to simulate an AZ failure it's worth considering the difference between the active infrastructure that will be disrupted. 

E.g. for the autoscaling setup we built for the **First Experiment** section, we can target EC2 instances in a given AZ for termination by filtering on `Placement.AvailabilityZone`. We _expect_ that the "control plane", in this case the associated autoscaling group, will start new instances to replace those terminated. However, since there is no actual AZ failure and the autoscaling group thus has no awareness of our experiment, the new instances will most likely be re-created in the AZ for which we wanted to simulate a failure.

## Approaches

### AZ impact for EC2 / ASG

As mentioned above, autoscaling groups (ASGs) will try to rebalance instances and will likely create new instances in the "affected" AZ. Workarounds for this, using custom SSM documents, include:

* temporarily [suspend ASG](https://docs.aws.amazon.com/autoscaling/ec2/userguide/as-suspend-resume-processes.html) scaling / rebalancing - this helps measure the immediate impact of an AZ failure but does not simulate healing / rebalancing that would happen in an actual outage.
* remove an AZ from the ASG / LB 
* ...

Approaches to avoid:

* do not modify Network Access Control Lists (NACLs) or security groups (SGs) as this will lead to churn when the ASG tries to spin up new instances and they fail to register as healthy.

### AZ impact for ECS / ASG

... 

### AZ impact for EKS / ASG

...

### AZ impact for Databases

...

### AZ impact for Lambda

...


