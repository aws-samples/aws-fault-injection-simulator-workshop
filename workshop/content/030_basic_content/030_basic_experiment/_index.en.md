---
title: "First Experiment"
weight: 30
---

In this section, we will cover the setup required for using AWS FIS to run our first fault injection experiment

## Experiment idea

In the previous section, we ensured that we can measure the user experience. We also have configured an Auto Scaling group that should make sure we can "always" provide a good experience to the customer. Let's validate this:

* **Given**: we have an Auto Scaling group with multiple instances
* **Hypothesis**: Failure of a single EC2 instance may lead to slower response times but should not affect service availability for our customers.


