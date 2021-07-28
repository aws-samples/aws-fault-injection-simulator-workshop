+++
title = "Baselining and Monitoring"
weight = 10
+++

Before we start down the path of injecting faults into our system we should consider the following thought experiment:

_"If a tree falls in a forest and no one is around to hear it, does it make a sound?"_
 
For the purpose of our fault injection experiments we can rephrase this in two ways:

_"If part of our system is disrupted and we do not receive any irate calls from users, did anything break?"_

_"If part of our system is disrupted and sysops isn't alerted, did anything break?"_

Think about this for a second. There is a distinct difference between those two statements because users and ops have very differnt experiences.

### What the users see

What the users see is immediate, e.g. the website not loading or loading slowly. What the users see is also an end-to-end test of all system components and not all components of the system are in your purview. E.g. you cannot see the speed of the users' network connection or the state of their DNS caches. Finally an individual user can have an experience entirely different from all other users. For this workshop this is particularly important for a particular edge case: developers and ops typically have better system configurations and better experiences than the average user but tend to rely on the anecdotal evidence of "it worked for me".

### What sysops sees

Typically what sysops see is a wealth of individual health and performance indicators. These have often grown organically from previous outages. Even where dashboards have been built with overall system health in mind the metrics are delayed against the user experience and aggregate over the experience of many users, requiring extra effort to notice poor experiences specific to a subset of users.

### Setting up for fault injection

Before starting our first fault injection experiment, let's have a look at our most basic infrastructure:

{{< img "BasicASG-with-user.png" "Image of architecture to be injected with chaos" >}}

We have a user trying to access a website running on AWS. We have designed for high availability by using EC2 instances with an auto-scaling group and a load balancer to ensure that the the user will always be able to reach our website even under heavy load or if an instance fails.

Once you've started the template as described in **Getting Started** you can navigate to [CloudFormation](https://console.aws.amazon.com/cloudformation/home), select the "FisStackAsg" stack and click on the "Outputs" tab which will show you the server URL:

{{< img "cloudformation.en.png" "Autoscaling group URL" >}}

To gain visibility into the user experience from the sysops side we've used the [cloudwatch agent](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/UseCloudWatchUnifiedAgent.html) to export our web server logs to [cloudwatch logs](https://console.aws.amazon.com/cloudwatch/home?#logsV2:log-groups/log-group/$252Ffis-workshop$252Fasg-access-log) and we created [CloudWatch Logs metrics filters](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/MonitoringLogData.html) to track server response codes and speeds on a [dashboard](https://console.aws.amazon.com/cloudwatch/home?#dashboards:name=fis-dashboard-1). The dashboard also shows the number of instances in our Auto-Scaling Group (ASG).

{{< img "fis-dashboard-1.png" "CloudWatch dashboard" >}}

{{%expand "Accessing the dashboard from the console" %}}
To access the dashboard, log into the AWS console as described in **Getting Started**. From the "Services" dropdown navigate to "CloudWatch" under "Management & Governance" or use the search bar. On the top left select "Dahsboards" and choose "fis-dashboard-1".
{{% /expand%}}

In the next section we will cover how to measure the user experience. 
