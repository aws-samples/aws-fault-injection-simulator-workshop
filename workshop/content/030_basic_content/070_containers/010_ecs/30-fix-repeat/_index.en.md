+++
title = "Improve & Repeat"
chapter = false
weight = 30
+++

## Learning and Improving

In the previous section we have identified some issues with our current setup: our ECS cluster only had one instance and our application's ECS Service desired capacity was set to **1**. Now, let's improve our infrastructure setup. 

In a browser window navigate to the *Auto Scaling Groups* section in the [EC2 console](https://console.aws.amazon.com/ec2autoscaling/home) and search for an auto scaling group named `EcsStack-EcsAsgProviderASGABCD0123-0987ZYXW65VU`, e.g. `EcsStack-EcsAsgProviderASG51CCF8BD-4LO6D3O44727`. Select the check box next to our Auto Scaling group. A split pane opens up in the bottom part of the Auto Scaling groups page, showing information about the group that's selected. 

{{< img "auto-scaling-group-details.en.png" "Auto Scaling Group Details" >}}

In the lower pane, in the **Details** tab, click the **Edit** button and change the current settings for maximum and desired capacity and set it to **2**. Click **Update** to complete the changes:

{{< img "auto-scaling-group-change-capacity.en.png" "Auto Scaling Group Change Size" >}}

Navigate to the *Clusters* section in the [ECS console](https://console.aws.amazon.com/ecs/home?#/clusters) and search for the cluster named `EcsStack-ClusterABCD0123-a1B2c3d4E5f6`, e.g. `EcsStack-ClusterEB0386A7-xJ4yY19a5jLP`. Click on the cluster name and look at the ECS service named `EcsStack-ClusterABCD0123-a1B2c3d4E5f6`, e.g. `EcsStack-ServiceD69D759B-PsBz3nNuocPp`, running on this cluster. Select the check box next to our ECS Service and click **Update**:

{{< img "ecs-service-update.en.png" "ECS Service Update" >}}

Scroll at the bottom of the *Configure service* screen and change the value of the **Number of tasks** setting from **1** to **2**. Click **Skip to review** and complete the process:

{{< img "ecs-service-update-number-tasks.en.png" "ECS Service Update Number of Tasks" >}}

## Repeat the experiment

Now that we have improved our configuration, let's re-run the experiment. This time we should observe that, even when one of the container instances gets terminated, our application is still available and successfully serving requests. In the output of the Bash script there should be no `HTTP 503 Service Temporarily Unavailable` return codes.