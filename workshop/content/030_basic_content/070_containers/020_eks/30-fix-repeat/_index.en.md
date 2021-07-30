+++
title = "Improve & Repeat"
chapter = false
weight = 30
+++

## Learning and Improving

In the previous section we have identified some issues with our current setup: our EKS cluster only had one worker node and our application's pod count was set to **1**. Now, let's improve our infrastructure setup. 

In a browser window navigate to the *Clusters* section in the [EKS console](https://console.aws.amazon.com/eks/home?#/clusters) and search for the cluster named `FisWorkshop-EksCluster`. Click on the cluster name, select the *Configuration* tab and then the *Compute* tab. In the *Node Groups* section, select the round check box next to the group named `FisWorkshopNG` and click **Edit**.

{{< img "eks-cluster-compute-configuration.en.png" "EKS Cluster Compute Configuration" >}}

On the *Edit node group* page, edit the current settings for maximum and desired size and set it to **2**:

{{< img "eks-cluster-update-node-group-size.en.png" "EKS Cluster Update Node Group Size" >}}

When you're finished editing, choose **Save changes**.

From a local terminal, run the following command to update the application's pod count to **2**:

```bash
kubectl scale --current-replicas=1 --replicas=2 deployment/hello-kubernetes
```

## Repeat the experiment

Now that we have improved our configuration, let's re-run the experiment. This time we should observe that, even when one of the container instances gets terminated, our application is still available and successfully serving requests. In the output of the Bash script there should be no `curl: (52) Empty reply from server` messages.