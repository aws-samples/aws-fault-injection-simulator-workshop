---
title: "Amazon EKS"
chapter: false
weight: 10
services: true
---

In this section we will cover working with containers running on [Amazon Elastic Kubernetes Service](https://aws.amazon.com/eks/) (EKS). For this setup we'll be using the following test architecture:

{{< img "EKSCluster-with-user.png" "Image of architecture to be injected with chaos" >}}

Amazon EKS gives you the flexibility to start, run, and scale Kubernetes applications in the AWS cloud or on-premises. Amazon EKS helps you provide highly-available and secure clusters and automates key tasks such as patching, node provisioning, and updates. EKS runs upstream Kubernetes and is certified Kubernetes conformant for a predictable experience. You can easily migrate any standard Kubernetes application to EKS without needing to refactor your code.

{{% notice note %}}
For this section, make sure you have `kubectl` installed in your local environment. Follow [these steps](https://docs.aws.amazon.com/eks/latest/userguide/install-kubectl.html) if you need to install `kubectl`. 
{{% /notice %}}

