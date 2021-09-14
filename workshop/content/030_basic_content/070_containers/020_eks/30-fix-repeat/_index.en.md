---
title: "Improve & Repeat"
chapter: false
weight: 30
services: true
---

## Learning and Improving

In the previous section we have identified some issues with our current setup: our EKS cluster only had **one** worker node and our application's pod count was set to `1`. Now, let's improve our infrastructure setup. 

### Increase the number of instances 

In a browser window navigate to the *Clusters* section in the [EKS console](https://console.aws.amazon.com/eks/home?#/clusters) and search for the cluster named `FisWorkshop-EksCluster`. Click on the cluster name, select the *Configuration* tab and then the *Compute* tab. In the *Node Groups* section, select the round check box next to the group named `FisWorkshopNG` and click **Edit**.

{{< img "eks-cluster-compute-configuration.en.png" "EKS Cluster Compute Configuration" >}}

On the *Edit node group* page

- Change the current settings for "minimum" to `2` to ensure we always have at least 2 instances available for redundancy. Note: if you only increase "desired" and "maximum" then the scaling policy for the auto scaling group could decrease the "desired" value back to `1` during low load periods.

- Set "desired" and "maximum" to `2` or more. Note: setting the desired value to more than the number of tasks (see below) will leave you with idle instances.

{{< img "eks-cluster-update-node-group-size.en.png" "EKS Cluster Update Node Group Size" >}}

When you're finished editing, scroll to the bottom and choose **Save changes**.

### Increase the number of containers

From a local terminal, run the following command to update the application's pod count to **2**:

```bash
kubectl scale --current-replicas=1 --replicas=2 deployment/hello-kubernetes
```

To verify, you can run `kubectl get pods` and `kubectl get deployments`. Here's the sample output.

```text
NAME                               READY   STATUS    RESTARTS   AGE
hello-kubernetes-ffd764cf9-5v7z9   1/1     Running   0          25s
hello-kubernetes-ffd764cf9-6bdbn   1/1     Running   0          4m43s
```

```text
NAME               READY   UP-TO-DATE   AVAILABLE   AGE
hello-kubernetes   2/2     2            2           46h
```

## Repeat the experiment

Now that we have improved our configuration, let's re-run the experiment. Before starting review the EKS Cluster to ensure that the instance capacity has increased to `2` and that the number of running containers is `2`.

This time we should observe that, even when one of the container instances gets terminated, our application is still available and successfully serving requests. In the output of the Bash script there should be no `curl: (52) Empty reply from server` messages.

## EKS/k8s cluster auto scaling

In this workshop we used manual scaling of both worker nodes and pods. In a production setup you would likely configure kubernetes / EKS to use 

* a [Cluster Autoscaler](https://docs.aws.amazon.com/eks/latest/userguide/cluster-autoscaler.html) that is aware of scaling needs based on pod configuration.
* a [Horizontal Pod Autoscaler](https://docs.aws.amazon.com/eks/latest/userguide/horizontal-pod-autoscaler.html) to dynamically manage the number of pods .
* a [Vertical Pod Autoscaler](https://docs.aws.amazon.com/eks/latest/userguide/vertical-pod-autoscaler.html) to dynamically manage CPU and memory allocation on your pods.

## EKS further learning

For more on EKS configurations see the [EKS workshop](https://www.eksworkshop.com/). 

