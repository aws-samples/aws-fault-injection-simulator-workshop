---
title: "Provision AWS resources"
chapter: false
weight: 50
servcies: true
---

{{% notice warning %}}
Only complete this section if you are running the workshop on your own. If you are at an AWS hosted event (such as re:Invent, Kubecon, Immersion Day, etc), these steps have already been executed for you.
{{% /notice %}}

Before we start running fault injection experiments we need to provision our resources in the cloud. The rest of the workshop uses these resources.

Clone the repository

```
cd ~/environment
git clone https://github.com/aws-samples/aws-fault-injection-simulator-workshop.git
```

Deploy the resources

```
cd aws-fault-injection-simulator-workshop
cd resources/templates
./deploy-parallel.sh
```

It can take up to 30 minutes to complete.  
