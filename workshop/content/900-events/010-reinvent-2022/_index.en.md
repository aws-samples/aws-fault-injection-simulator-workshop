---
title: "re:invent 2022 - DOP313"
chapter: false
weight: 10
services: true
draft: true
---

The instructions collected here are aligned with a specific session at re:Invent 2022 for your convenience. These labs draw on other sections of the workshop and you may choose to explore those other sections further. 

This builder session is targeted at 300 level. We assume that you are familiar with the use of the AWS console and have familiarity with CloudWatch Dashboards. 

## Lab 1 - Review basic FIS experiment (5-10min)

We hope that you have tried FIS before but might need a refresher. Since we are assuming that you have an understanding how to create resources in AWS in general, let's use some automation to create the basic FIS experiment.

### Pre-create resources

* On the AWS console, navigate to [**AWS CloudShell**](https://console.aws.amazon.com/cloudshell/home) - see [**Configure AWS Cloudshell**]({{<ref "020_starting_workshop/020_aws_event/cloudshell" >}}) for more details

* Initialize the environment and check out the GitHub repository
  ```bash
  mkdir -p ~/environment
  cd ~/environment
  git clone https://github.com/aws-samples/aws-fault-injection-simulator-workshop.git
  ```

* Ensure you have up to date utilities installed
  ```bash
  # Update to the latest stable release of npm and nodejs.
  sudo npm install -g stable 

  # Install typescript
  sudo npm install -g typescript

  # Install CDK
  sudo npm install -g aws-cdk

  # Install the jq tool
  sudo yum install -y jq gettext
  ```

* Create server role and populate environment variables
  ```bash
  source ~/environment/aws-fault-injection-simulator-workshop/resources/code/scripts/cheat.sh 1 2 3
  ```

Your environment should now be in a similar state to where you would have been after doing the following steps in the workshop:

* [**Baselining and Monitoring**]({{<ref "030_basic_content/010-baselining">}})
* [**Synthetic User Experience**]({{<ref "030_basic_content/020_working_under_load">}})
* [**First Experiment / Configuring Permissions**]({{<ref "030_basic_content/030_basic_experiment/10-permissions">}})
* [**First Experiment / Experiment (Console)**]({{<ref "030_basic_content/030_basic_experiment/20-experiment-console" >}})

### Exploring FIS

Let's explore the experiment template that was created for you. Navigate to the [**FIS console**](https://console.aws.amazon.com/fis/home?#ExperimentTemplates:v=3&tag:Name=FisWorkshopExp1Run1) and search for a template named `FisWorkshopExp1Run1`. Select the template ID:

{{< img "dop313-template-find.png" "Find FIS template" >}}

Select "Update" to explore how the template is configured, then follow the validation procedure from the [**First Experiment section**]({{<ref "030_basic_content/030_basic_experiment/20-experiment-console#validation-procedure">}}).

{{< img "dop313-template-modify-and-run.png" "Explore FIS template" >}}


## Lab 2 - Extend FIS with AWS Systems Manager (5-10min)

### Pre-create resources

In this section we explore how to extend FIS to use AWS Systems Manager (SSM) automation documents. Let's use some automation to pre-create the required IAM role. Please ensure that you've performed the pre-creation steps in the previous section as well:

* On the AWS console, navigate to [**AWS CloudShell**](https://console.aws.amazon.com/cloudshell/home) - see [**Configure AWS Cloudshell**]({{<ref "020_starting_workshop/020_aws_event/cloudshell" >}}) for more details

* Create SSM role and populate environment variables
  ```bash
  source ~/environment/aws-fault-injection-simulator-workshop/resources/code/scripts/cheat.sh 5
  ```

Your environment should now be in a similar state to where you would have been after creating the `FisWorkshopSsmEc2DemoRole` SSM role and updating the `FisWorkshopServiceRole` as described in [**FIS SSM Start Automation Setup**]({{<ref "030_basic_content/040_ssm/050_direct_automation#configure-permissions">}}). 

### Exploring FIS + SSM

In the previous lab you terminated an EC2 instance in an auto-scaling group by filtering on a `Name` tag. In this section we will show you how to use an SSM automation document that takes an autoscaling group ARN and an AZ name to achieve the same thing.

Follow the instructions in the [**Create SSM document**]({{<ref "030_basic_content/040_ssm/050_direct_automation#create-ssm-document">}}) section of the **FIS SSM Start Automation Setup** page. You should now have an SSM document. Navigate to the [**SSM console**](https://console.aws.amazon.com/systems-manager/documents), select "Documents" at the bottom of the burger menu, then select "Owned by me" and search for `TerminateAsgInstancesWithSsm`. 

{{< img "dop313-ssm-find.png" "Explore SSM template" >}}

Now we need to create a FIS template using our newly created SSM document. You can follow the instructions in the [**Create FIS Experiment Template**]({{<ref "030_basic_content/040_ssm/050_direct_automation#create-fis-experiment-template">}}) section of the **FIS SSM Start Automation Setup** page or you can run this script:

```bash
source ~/environment/aws-fault-injection-simulator-workshop/resources/code/scripts/cheat.sh 9
```

With the FIS template created you can now run the FIS template from the [**FIS console**](https://console.aws.amazon.com/fis/home?#ExperimentTemplates:v=3&tag:Name=FisWorkshopDop313) and observe the impact on the CloudWatch dashboard like in Lab 1. 


## Lab 3 - Explore AZ outage simulations (30-40min)

