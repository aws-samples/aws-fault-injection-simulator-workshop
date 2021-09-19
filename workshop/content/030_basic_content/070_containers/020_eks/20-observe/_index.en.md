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

Code 000 Duration 0.093033 
Code 000 Duration 0.088688 
Code 000 Duration 0.086454 
Code 000 Duration 0.088505 
Code 000 Duration 0.097665 

...

Code 200 Duration 0.082434 
Code 200 Duration 0.081427 
Code 200 Duration 0.087983 
Code 200 Duration 0.081950 
Code 200 Duration 0.082790 
```

You'll notice that not all the requests were successful, As the FIS experiment starts you should see some `000` return codes. This is not a legal HTTP response code. If we just ran curl as 

```bash
curl $EKS_URL
```

we would see an error message indicating that the server just closed the connection on us.

```text
curl: (52) Empty reply from server
```
In practice this means our application was not available for a period of time. This is not what we were expecting, so let's dive a bit deeper to find out why it happened.

### Configure kubectl

{{% notice note %}}
Make sure you have `kubectl` installed in your local environment. Follow [these steps](https://docs.aws.amazon.com/eks/latest/userguide/install-kubectl.html) if you need to install `kubectl`. 
{{% /notice %}}


We will follow [these steps](https://docs.aws.amazon.com/eks/latest/userguide/create-kubeconfig.html#create-kubeconfig-automatically) to update the `kubectl` configuration to securely connect to the EKS cluster. The cluster is named `FisWorkshop-EksCluster`. To find the ARN of the kubectl access role, navigate to the [CloudFormation console](https://console.aws.amazon.com/cloudformation/home?#/stacks?filteringStatus=active&filteringText=FisStackEks&viewNested=true&hideStacks=false), select the `FisStackEks` stack, Select "Outputs", and copy the value of "FisEksKubectlRole".

From a local terminal, run the following command to configure kubectl:
 
```bash
# verify you have aws CLI installed
aws --version

# Retrieve the role ARN
KUBECTL_ROLE=$( aws cloudformation describe-stacks --stack-name FisStackEks --query "Stacks[*].Outputs[?OutputKey=='FisEksKubectlRole'].OutputValue" --output text )

# Configure kubectl with cluster name and ARN
aws eks update-kubeconfig --name FisWorkshop-EksCluster --role-arn ${KUBECTL_ROLE}
```

{{% notice note %}}
If you get the message **"error: You must be logged in to the server (Unauthorized)"** when running `kubectl` command, please follow [these steps](https://aws.amazon.com/premiumsupport/knowledge-center/eks-api-server-unauthorized-error/) to troubleshoot the problem. 
{{% /notice %}}

### Check number of containers

From a local terminal, run the following command to check our application service configuration:

```bash
kubectl get pods
```

You'll notice that there's only one pod named `hello-kubernetes-...` - e.g. `hello-kubernetes-ffd764cf9-zwnq7` - meaning that only one copy of our containerized application is running at any time. 

```text
NAME                               READY   STATUS    RESTARTS   AGE
hello-kubernetes-ffd764cf9-zwnq7   1/1     Running   0          8m34s
```

### Check number of instances

In the same terminal, run the following command to check the nodes in our cluster:

```bash
kubectl get nodes
```

In the output you'll see that our cluster only has a single worker node.

```text
NAME                                         STATUS   ROLES    AGE   VERSION
ip-10-0-150-147.eu-west-1.compute.internal   Ready    <none>   12m   v1.20.4-eks-6b7464
```

### Observations 

This configuration is not optimal:

- A cluster with a single worker node means that if that instance fails, all the containers running on that instance will also be killed. This is what happened during our experiment and the reason why we observed some `curl: (52) Empty reply from server` messages. We should change this so that our cluster has more than one instance across multiple Availability Zones (AZs).

- An EKS workload with **one** pod also means that if that pod fails, there aren't any other pods to continue serving requests. We can modify this by adjusting the pod count to `2` (or any number greater than `1`).

Now that we have identified some issues with our current setup, let's move to the next section to fix them.
