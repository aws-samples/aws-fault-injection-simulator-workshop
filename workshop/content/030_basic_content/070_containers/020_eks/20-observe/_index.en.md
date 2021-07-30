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
  0   664    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
HTTP/1.1 200 OK
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
curl: (52) Empty reply from server
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
curl: (52) Empty reply from server
```

You'll notice that not all the requests were successful, you should see some `curl: (52) Empty reply from server` messages. This means our application was not available for a period of time. This is not what we were expecting, so let's dive a bit deeper to find out why it happened.

{{% notice note %}}
Make sure you have `kubectl` installed in your local environment. Follow [these steps](https://docs.aws.amazon.com/eks/latest/userguide/install-kubectl.html) if you need to install `kubectl`. 
{{% /notice %}}

Update the `kubectl` configuration to work with your EKS cluster. Follow [these steps](https://docs.aws.amazon.com/eks/latest/userguide/create-kubeconfig.html#create-kubeconfig-automatically) and use `FisWorkshop-EksCluster` as the cluster name.

From a local terminal, run the following command to check our application service configuration:

```bash
kubectl get pods
```

You'll notice that there's only one pod named `hello-kubernetes-abcd1234e-567fg` - e.g. `hello-kubernetes-ffd764cf9-zwnq7` - meaning that only one copy of our containerized application is running at any time. 

```bash
NAME                               READY   STATUS    RESTARTS   AGE
hello-kubernetes-ffd764cf9-zwnq7   1/1     Running   0          8m34s
```

In the same terminal, run the following command to check the nodes in our cluster:

```bash
kubectl get nodes
```

In the output you'll see that our cluster only has a single worker node.

```bash
NAME                                         STATUS   ROLES    AGE   VERSION
ip-10-0-150-147.eu-west-1.compute.internal   Ready    <none>   12m   v1.20.4-eks-6b7464
```

This configuration is not optimal:
- A cluster with a single worker node means that if that instance fails, all the containers running on that instance will also be killed. This is what happened during our experiment and the reason why we observed some `curl: (52) Empty reply from server` messages. We should change this so that our cluster has more than one instance across muliple Avalability Zones (AZs).
- An EKS workload with **1** pod also means that if that pod fails, there aren't any other pods to continue serving requests. We can modify this by adjusting the pod count to **2** (or any number greater than 1).

Now that we have identified some issues with our current setup, let's move to the next section to fix them.
