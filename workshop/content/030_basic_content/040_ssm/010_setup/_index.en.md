---
title: "FIS SSM Send Command Setup"
weight: 10
services: true
---

For this section we will use Linux and Windows instances created specifically for the purpose of enabling FIS SSM commands. As shown in the diagram below, SSM access to the instance [**requires an instance role**](https://docs.aws.amazon.com/systems-manager/latest/userguide/setup-instance-profile.html#instance-profile-policies-overview) with the `AmazonSSMManagedInstanceCore` policy attached. Additionally FIS access to SSM is controlled via the execution policy as shown in the [**First Experiment**]({{< ref "030_basic_experiment" >}}) section. 

{{< img "StressTest-with-user.en.png" "Stress test architecture" >}}


{{% notice info %}}
The resources above have been created as part of the account setup or in the [**Start the workshop**]({{< ref "020_starting_workshop/010_self_paced/050_create_stack" >}}) section.  If you would like to examine how these resources were defined you can examine the [**AWS Cloud Formation template**](https://github.com/aws-samples/aws-fault-injection-simulator-workshop/blob/main/resources/templates/cpu-stress/CPUStressInstances.yaml). 
{{% /notice %}}
