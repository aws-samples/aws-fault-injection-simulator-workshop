---
title: "Baselining and Monitoring"
weight: 10
services: true
---

Before we start injecting faults into our system we should consider the following thought experiment:

> _"If a tree falls in a forest and no one is around to hear it, does it make a sound?"_
 
For the purpose of our fault injection experiments we can rephrase this in two ways:

> _"If part of our system is disrupted and we do not receive any irate calls from users, did anything break?"_

> _"If part of our system is disrupted and sysops isn't alerted, did anything break?"_

Think about this for a second. There is a distinct difference between those two statements because users and Ops teams have very different experiences.

## What the users see

What the users see is immediate, e.g. the website not loading or loading slowly. What the users see is also an end-to-end test of all system components, and not all components of the system are in your purview, e.g. you cannot see the speed of the users' network connection or the state of their DNS caches. Finally an individual user can have an experience entirely different from all other users. For this workshop, this is particularly important for a particular edge case: developers and ops typically have better system configurations and better experiences than the average user but tend to rely on the anecdotal evidence of "it worked for me".

## What sysops sees

Typically, what SysOps see is a wealth of individual health and performance indicators. These often grow organically over time and especially after outages. Even where dashboards have been built with overall system health in mind, the metrics are delayed against the user experience and aggregate over the experience of many users, requiring extra effort to notice poor experiences specific to a subset of users.

## To disrupt production - or not 

Chaos engineering was popularized by Netflix who famously ran it in production. This view of chaos engineering being a production practice is so entrenched that it was even spelt out in the [wikipedia definition](https://en.wikipedia.org/wiki/Chaos_engineering).

> _Chaos engineering is the discipline of experimenting on a software system **in production** in order to build confidence in the system's capability to withstand turbulent and unexpected conditions._

This is so counterintutive that Gene Kim used to have a section in his presentations where he would spell this out to immediate audience laughter:

> _One of the things people don't tell you about chaos engineering: before you do it in production, do it in dev/test._

Once you stop laughing, stop to think: if _you_ ran a chaos experiment in dev/test, would you have the same monitoring and alerting? Would you know if anything broke?

## Setting up for fault injection

Before starting our first fault injection experiment, let's take a look at our most basic infrastructure:

{{< img "BasicASG-with-user.png" "Image of architecture to be injected with chaos" >}}

We have a user trying to access a website running on AWS. We have designed it for high availability. We used EC2 instances with an Auto Scaling group and a load balancer to ensure that users can always reach our website even under heavy load or if an instance suddenly fails.

Once you've created the resources as described in [**Provision AWS resources**]({{< ref "020_starting_workshop/010_self_paced/050_create_stack" >}}) you can navigate to [**CloudFormation**](https://console.aws.amazon.com/cloudformation/home), select the `FisStackAsg` stack and select the **"Outputs"** tab which will show you the server URL:

{{< img "cloudformation.en.png" "Auto Scaling group URL" >}}

To gain visibility into the user experience from the sysops side we've used the [**AWS CloudWatch agent**](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/UseCloudWatchUnifiedAgent.html) to export our web server logs to [**AWS CloudWatch Logs**](https://console.aws.amazon.com/cloudwatch/home?#logsV2:log-groups/log-group/$252Ffis-workshop$252Fasg-access-log) and we created [**AWS CloudWatch Logs metrics filters**](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/MonitoringLogData.html) to track server response codes and speeds on a [**dashboard**](https://console.aws.amazon.com/cloudwatch/home?#dashboards:name=FisDashboard-us-west-2). Note that the dashboard's name is based on the region in which we deployed. If you chose a region other than `us-west-2` the dashboard's name will be different. The dashboard also shows the number of instances in our Auto Scaling Group (ASG).

{{< img "fis-dashboard-1.png" "CloudWatch dashboard" >}}

{{%expand "Accessing the dashboard from the console" %}}
To access the dashboard, log into the AWS console as described in [**Start the workshop**]({{< ref "020_starting_workshop" >}}). From the "**Services**" dropdown navigate to "**CloudWatch**" under "**Management & Governance**" or use the search bar. On the top left select "**Dashboards**" and choose `FisDashboard-us-west-2` (or the appropriate dashboard's name based on the region you selected).
{{% /expand%}}

In the next section we will cover how to measure the user experience. 
