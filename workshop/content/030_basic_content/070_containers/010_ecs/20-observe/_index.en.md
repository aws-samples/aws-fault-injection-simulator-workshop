+++
title = "Observe the system"
chapter = false
weight = 20
+++

### Review results

Let's take a look at the output in the terminal window where your Bash script is running:

```text
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
HTTP/1.1 200 OK
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0   162    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
HTTP/1.1 503 Service Temporarily Unavailable
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0   162    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
HTTP/1.1 503 Service Temporarily Unavailable
```

You'll notice that not all the requests were successful, you should see some `HTTP 503 Service Temporarily Unavailable` return codes. This means our application was not available for a period of time. This is not what we were expecting, so let's dive a bit deeper to find out why it happened.

In a new browser window navigate to the *Clusters* section in the [ECS console](https://console.aws.amazon.com/ecs/home?#/clusters) and search for the cluster named `EcsStack-ClusterABCD0123-a1B2c3d4E5f6`, e.g. `EcsStack-ClusterEB0386A7-xJ4yY19a5jLP`. Click on the cluster name and look at the ECS services running on this cluster:

{{< img "ecs-cluster-services.en.png" "ECS Cluster Services" >}}

You'll notice that the service named `EcsStack-ClusterABCD0123-a1B2c3d4E5f6`, e.g. `EcsStack-ServiceD69D759B-PsBz3nNuocPp` - i.e. our application - only has **1** desired task, meaning that only one copy of our containerized application will be running at any time. 

{{< img "ecs-service-desired-capacity.en.png" "ECS Cluster Services" >}}

Now click on the **ECS Instances** tab. You'll see here that there's only one instance registered with our cluster. 

{{< img "ecs-cluster-instances.en.png" "ECS Cluster Services" >}}

This configuration is not optimal:
- A cluster with a single instance means that if that instance fails, all the containers running on that instance will also be killed. This is what happened during our experiment and the reason why we observed some `HTTP 503 Service Temporarily Unavailable` return codes. We should change this so that our cluster has more than one instance across muliple Avalability Zones (AZs).
- Having an ECS Service with **1** desired task also means that if that task fails, there aren't any other tasks to continue serving requests. We can modify this by adjusting the desired task capacity to **2** (or any number greater than 1).

Now that we have identified some issues with our current setup, let's move to the next section to fix them.
