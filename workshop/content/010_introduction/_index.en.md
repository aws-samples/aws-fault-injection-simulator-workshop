+++
title = "Workshop Introduction"
chapter = true
weight = 10
+++

This workshop provides an introduction to chaos engineering using AWS tooling, with a core focus on AWS Fault Injection Simulator. It introduces the core elements of chaos engineering: stress, observe, and improve. You will learn how to use FIS to stress / disrupt infrastructure to validate resilience in your system setup and demonstrates how to use other AWS tools to observe and improve your system resilience.

## Target audience

This is a technical workshop introducing chaos engineering concepts to and audience of developers, QA and and Ops. For best results the participants should have familiarity with the AWS console as well as some proficiency with command-line tooling. 

Additionally, chaos engineering revolves around building hypotheses of how a particular disruption will affect overall system behavior so an understanding of the systems being disrupted is generally helpful but not required to do the workshop.

## Duration

When run in a prepared AWS account the core sections (EC2, RDS, SSM) of the workshop will take about 1-2h and the whole workshop about 2-4h. Using the Amazon DevOps Guru section will require an additional 2-24h of wait time after the infrastructure has been configured.

When run in a customer account, infrastructure initialization for the core workshop will require and additional 45min. 

## Cost

If running in a customer account this workshop will incur costs on the order of USD1/h for the infrastructure created. Please ensure that you clean up all infrastructure after finishing the workshop to prevent generating continuing expenses. You can find instructions in the **Cleanup** section. 
