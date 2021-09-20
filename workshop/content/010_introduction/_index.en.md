---
title: "Introduction"
chapter: true
weight: 10
services: true
---
This workshop provides an introduction to chaos engineering using Amazon Web Services (AWS) tooling, with a focus on AWS Fault Injection Simulator (FIS). It introduces the core elements of chaos engineering: 

* form a hypothesis (plan),
* introduce stress (do),
* observe (check), and 
* improve (act). 

You will learn how to use FIS and other AWS tools to inject faults in your infrastructure to validate your system's resilience as well as verifying your alarms, observability, and monitoring practices.

## Target audience

This is a technical workshop introducing chaos engineering practices for Dev, QA and Ops teams. For best results, the participants should have familiarity with the AWS console as well as some proficiency with command-line tooling. 

Additionally, chaos engineering is about proving or disproving a hypothesis of how a particular fault might affect the overall system behavior (steady-state) so an understanding of the systems being disrupted is helpful but not required to do the workshop.

## Duration

When run in a prepared AWS account the core sections of the workshop will take between 1-2h. The whole workshop about 2-4h. Using the Amazon DevOps Guru section will require an additional 2-24h of wait time after the infrastructure has been configured.

When run in a customer account, deploying the workshop's core infrastructure will require an additional 45min. 

## Cost

When run in a private customer account, this workshop will incur costs on the order of USD1/h for the infrastructure created. Please ensure you clean up all infrastructure after finishing the workshop to prevent continuing expenses. You can find instructions in the [**Cleanup**]({{< ref "990_cleanup" >}}) section. 
