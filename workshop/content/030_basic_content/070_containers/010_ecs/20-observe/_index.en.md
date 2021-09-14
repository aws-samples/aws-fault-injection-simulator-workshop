---
title: "Observe the system"
chapter: false
weight: 20
services: true
---

## Review results

Let's take a look at the output in the terminal window where your Bash script is running:

```text
Code 200 Duration 0.137204 
Code 200 Duration 0.080911 
Code 200 Duration 0.081539 
Code 200 Duration 0.077265 
Code 200 Duration 0.085331 
Code 200 Duration 0.081634 

...

Code 503 Duration 0.083001 
Code 503 Duration 0.088983 
Code 502 Duration 0.085972 
Code 502 Duration 0.086619 
Code 502 Duration 0.086554 
Code 503 Duration 0.083428 
Code 502 Duration 0.084929 

...

Code 200 Duration 0.082434 
Code 200 Duration 0.081427 
Code 200 Duration 0.087983 
Code 200 Duration 0.081950 
Code 200 Duration 0.082790 
```

You'll notice that as not all the requests were successful. As the FIS experiment starts you should see some [HTTP 502](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/502) "Bad Gateway" and [HTTP 503](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/503) "Service Unavailable" return codes. This means our application was not available for a period of time. This is not what we were expecting, so let's dive a bit deeper to find out why it happened.

### Check number of containers

In a new browser window navigate to the *Clusters* section in the [ECS console](https://console.aws.amazon.com/ecs/home?#/clusters) and search for the cluster named `FisStackEcs-Cluster...`, e.g. `FisStack-ClusterEB0386A7-xJ4yY19a5jLP`. Click on the cluster name and look at the ECS services running on this cluster:

{{< img "ecs-cluster-services.en.png" "ECS Cluster Services overview" >}}

You'll notice that the service named `FisStackEcs-SampleAppService...`, e.g. `FisStackEcs-SampleAppServiceD69D759B-PsBz3nNuocPp` - i.e. our application - only has **one** desired task, meaning that only one copy of our containerized application will be running at any time. 

{{< img "ecs-service-desired-capacity.en.png" "ECS Cluster Services showing single desired task" >}}

### Check number of instances 

Now click on the "ECS Instances" tab. You'll see here that there's only one instance registered with our cluster. 

{{< img "ecs-cluster-instances.en.png" "ECS Cluster Services showing single running instance" >}}

### Observations

This configuration is not optimal:

- A cluster with a single instance means that if that instance fails, all the containers running on that instance will also be killed. This is what happened during our experiment and the reason why we observed some [HTTP 503](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/503) "Service Unavailable" return codes. We should change this so that our cluster has more than one instance across multiple Availability Zones (AZs).

- Having an ECS Service with **one** desired task also means that if that task fails, there aren't any other tasks to continue serving requests. We can modify this by adjusting the desired task capacity to `2` (or any number greater than `1`).

Now that we have identified some issues with our current setup, let's move to the next section to fix them.
