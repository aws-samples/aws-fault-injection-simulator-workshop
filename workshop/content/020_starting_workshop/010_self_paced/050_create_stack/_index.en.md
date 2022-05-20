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

{{% notice note %}}
Instantiating all resources will take about 30 minutes. This might be a good time to read ahead at [**Baselining and Monitoring**]({{<ref "030_basic_content/010-baselining">}}) or go for coffee.
{{% /notice %}}

Review the deploy output. It should similar to this:

```
Substack vpc SUCCEEDED
Substack goad-cdk SUCCEEDED
Substack access-controls SUCCEEDED
Substack serverless SUCCEEDED
Substack rds SUCCEEDED
Substack asg-cdk SUCCEEDED
Substack eks SUCCEEDED
Substack ecs SUCCEEDED
Substack cpu-stress SUCCEEDED
Substack api-failures SUCCEEDED
Substack spot SUCCEEDED
Overall install SUCCEEDED
```

If any of the substacks report as `FAILED` you can try to re-run the deployment script. If that still fails you can find some debugging information in files named `deploy-output.*.txt`.
