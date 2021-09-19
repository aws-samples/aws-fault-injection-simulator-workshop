---
title: "AWS Systems Manager Integration"
weight: 50
services: true
---

In this section, we will demonstrate how you can use [**AWS Systems Manager (SSM)**](https://docs.aws.amazon.com/systems-manager/latest/userguide/what-is-systems-manager.html) along with AWS Fault Injection Simulator (FIS) to emulate faults within an EC2 Instance.

AWS FIS does not need an agent for actions affecting the AWS control plane like the ones we have worked with thus far, such as stopping instances or failing over Amazon Relational Database Service (RDS) Databases. However, there are actions that require us to initiate commands within the operating system of the EC2 Instance, such as affecting CPU or Memory consumption, or terminating processes. For these types of actions AWS FIS can use AWS Systems Manager (SSM) and the [**SSM Agent**](https://docs.aws.amazon.com/systems-manager/latest/userguide/ssm-agent.html). This approach provides you with the access controls to grant FIS limited access to your instances under the [**shared responsibility model**](https://aws.amazon.com/compliance/shared-responsibility-model/).

In the following sections we will show you how to use the built-in SSM actions and how to build your own SSM documents to create custom actions.
