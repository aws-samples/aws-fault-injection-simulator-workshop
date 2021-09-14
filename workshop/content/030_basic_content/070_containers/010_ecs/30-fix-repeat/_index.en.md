---
title: "Improve & Repeat"
chapter: false
weight: 30
services: true
---

## Learning and Improving

In the previous section we have identified some issues with our current setup: our ECS cluster only had **one** instance and our application's ECS Service desired capacity was set to `1`. Now, let's improve our infrastructure setup. 

### Increase the number of instances 

In our ECS configuration we have chosen to use EC2 with an auto scaling group as our capacity provider. To adjust desired instance capacity open a browser window and navigate to the *Auto Scaling Groups* section in the [EC2 console](https://console.aws.amazon.com/ec2autoscaling/home) and search for an auto scaling group named `FisStackEcs-EcsAsgProvider...`, e.g. `FisStackEcs-EcsAsgProviderASG51CCF8BD-4LO6D3O44727`. Select the check box next to our Auto Scaling group. A split pane opens up in the bottom part of the Auto Scaling groups page, showing information about the group that's selected. 

{{< img "auto-scaling-group-details.en.png" "Auto Scaling Group Details" >}}

In the lower pane, in the **Details** tab and under **Group details** section, click the **Edit** button.

- Change the current settings for "minimum" to `2` to ensure we always have at least 2 instances available for redundancy. Note: if you only increase "desired" and "maximum" then the scaling policy for the auto scaling group could decrease the "desired" value back to `1` during low load periods.

- Set "desired" and "maximum" to `2` or more. Note: setting the desired value to more than the number of tasks (see below) will leave you with idle instances.

- Click **Update** to complete the changes:

{{< img "auto-scaling-group-change-capacity.en.png" "Auto Scaling Group Change Size" >}}

### Increase the number of tasks

Navigate to the *Clusters* section in the [ECS console](https://console.aws.amazon.com/ecs/home?#/clusters) and search for the cluster named `FisStackEcs-Cluster...`, e.g. `FisStackEcs-ClusterEB0386A7-xJ4yY19a5jLP`. Click on the cluster name and look at the ECS service named `FisStackEcs-SampleAppService...`, e.g. `FisStackEcs-SampleAppServiceD69D759B-PsBz3nNuocPp`, running on this cluster. Select the check box next to our ECS Service and click **Update**:

{{< img "ecs-service-update.en.png" "ECS Service Update" >}}

Scroll to the bottom of the *Configure service* screen and change the value of the **Number of tasks** setting from `1` to `2`. Click **Skip to review** and complete the process by selecting **Update Service**.

{{< img "ecs-service-update-number-tasks.en.png" "ECS Service Update Number of Tasks" >}}

## Repeat the experiment

Now that we have improved our configuration, let's re-run the experiment. Before starting review the ECS Cluster to ensure that the instance capacity has increased to `2` and that the number of running tasks is `2`.

This time we should observe that, even when one of the container instances gets terminated, our application is still available and successfully serving requests. In the output of the Bash script there we should no longer see the [HTTP 503](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/503) "Service Unavailable" return codes.

## ECS further learning

For more on ECS configurations see the [ECS workshop](https://ecsworkshop.com/).
