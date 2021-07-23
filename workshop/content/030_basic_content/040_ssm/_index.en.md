+++
title = "AWS Systems Manager Integration"
date =  2021-07-07T17:25:37-06:00
weight = 5
+++

In this section, we will demonstrate how you can use AWS Systems Manager (SSM) along with AWS Fault Injection Simulator (FIS) to emulate faults within an EC2 Instance.

AWS FIS does not need an agent for most actions like the ones we have worked with thus far, such as stop instances or failing over RDS Databases. However, there are other conditions that will impact our application like CPU or Memory consumption. These types of actions require us to initiate actions within the operating system of the EC2 Instance. AWS FIS can use AWS SSM and the SSM Agent in order to emulate these types of events. In this section will demonstrate CPU stress for Linux or Windows Instances. 

In the next section we will cover setup for this lab. We will deploy a single instances for Windows or Linux as well as the supporting IAM roles for the experiment and the Instance. 