+++
title = "Workshop Overview"
chapter = true
weight = 30
+++

This workshop is broken into multiple chapters. The chapters are designed to be done in sequence. At the end of each chapter we include a "cheat" that should allow you to easily implement all the work required and allow you to move forward to the next chapter if you are already familiar with the material covered.

## Chapters:

{{% children %}}

## Architecture Diagrams

This workshop is focused on how to inject fault into an existing infrastructure. For this purpose the template in the **GettingStarted** section sets up a variaty of components. Throughout this workshop we will be showing you architecture diagrams focusing on only the components relevant to the section, e.g.:

{{< img "BasicASG.png" "Image of architecture to be injected with chaos" >}}

You can click on these images to enlarge them.

TODO LIST

* CloudWatch dashboard to monitor environment
* extensive tagging for filter examples
* RDS to keep state and demonstrate RDS failure / fail-over actions
* RDS Aurora - not actually FIS but sufficiently related to include here - https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraMySQL.Managing.FaultInjectionQueries.html
* EC2 instances without ASG - to demonstrate stop/start; SSM commands to kill/stress
* EC2 instances with ASG/ALB - to demonstrate scaling behavior and chaos injecton under load: terminate instances as well as ; SSM commands to kill/stress
* CI/CD pipeline to demonstrate running chaos injection as part of testing process
* ECS cluster to simulate container failure/draining
* EKS cluster to demonstrate worker node/node-group failure