---
title: "Introduction"
chapter: false
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

### Core sections

For an introductory workshop we recommend the following core sections:

* Baselining and Monitoring
* Synthetic User Experience
* First Experiment > Configuring Permissions
* First Experiment > Experiment (Console)
* AWS Systems Manager Integration > FIS SSM Send Command Setup
* AWS Systems Manager Integration > Linux CPU Stress Experiment
* AWS Systems Manager Integration > Working with SSM documents
* AWS Systems Manager Integration > Optional - Windows CPU Stress Experiment
* AWS Systems Manager Integration > FIS SSM Start Automation Setup
* AWS Systems Manager Integration > SSM Additional resources
* Databases > RDS DB Instance Reboot

When run in a prepared AWS account these core sections of the workshop will take about 2-3h. When run in a customer account, deploying the workshop's core infrastructure will require an additional 45min. 

### Additional sections

All remaining sections are intended as independent modules that can be added based on customer need and interest. All sections require the roles created in

* First Experiment > Configuring Permissions
* AWS Systems Manager Integration > FIS SSM Start Automation Setup

## Cost

When run in a private customer account, this workshop will incur costs on the order of USD1/h for the infrastructure created. Please ensure you clean up all infrastructure after finishing the workshop to prevent continuing expenses. You can find instructions in the [**Cleanup**]({{< ref "990_cleanup" >}}) section. 
