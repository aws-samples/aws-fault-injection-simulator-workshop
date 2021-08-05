+++
title = "First Experiment"
weight = 30
+++

In this section we will cover the setup required for running FIS and run our first experiment

## Experiment idea

In the [previous section]({{< ref "/030_basic_content/020_working_under_load" >}}) we ensured that we can measure the user experience. We have also configured an autoscaling group that should ensure that we can "always" provide a good experience to the customer. Let's validate this:

* **Given**: we have an autoscaling group with multiple instances
* **Hypothesis**: failure of a single EC2 instances may lead to slower response times but our customers will always have service.


