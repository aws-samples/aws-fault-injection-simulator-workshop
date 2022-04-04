---
title: "Linux CPU Stress Experiment"
weight: 20
services: true
---

## Experiment idea

In this section we are exploring tooling so we will start without a hypothesis. However, we will provide some learnings and next steps at the end.

Specifically, in this section we will run a CPU Stress test using AWS Fault Injection Simulator against an Amazon Linux EC2 Instance. The Linux [**CPU stress**](https://docs.aws.amazon.com/fis/latest/userguide/actions-ssm-agent.html#fis-ssm-docs) test is an out of the box FIS action. We will do the following: 

1. Create experiment template to stress CPU.
2. Connect to a Linux EC2 Instance and run the `top` command.
3. Start experiment and observe results.

## Experiment setup

{{% notice note %}}
We are assuming that you know how to set up a basic FIS experiment and will focus on things specific to this experiment. If you need a refresher see the previous [**First Experiment**]({{< ref "030_basic_content/030_basic_experiment/" >}}) section.
{{% /notice %}}

### General template setup

* Create a new experiment template
  * Add a name for the template using a Tag with key as `Name` and value as `LinuxBurnCPUviaSSM` (located at bottom of page)
  * Add `Description` of `Inject CPU stress on Linux`
  * Select `FisCpuStress-FISRole` as execution role

### Action definition 

In the "Actions" section select the **"Add Action"** button. 

Name the Action as `StressCPUViaSSM`, and under "Action Type" select `aws:ssm:send-command/AWSFIS-Run-Cpu-Stress`. This is an out of the box action to run stress test on Linux Instances using the [**stress-ng**](https://kernel.ubuntu.com/git/cking/stress-ng.git/) tool. Set the "documentParameters" field to `{"DurationSeconds":120}` which is passed to the script and the "duration" field to `2` minutes which tells FIS how long to wait for a result. Leave the default “Target” `Instances-Target-1` and select **"Save"**. 

{{< img "StressActionSettings.png" "Action Settings" >}}

This action will use [**AWS Systems Manager Run Command**](https://docs.aws.amazon.com/systems-manager/latest/userguide/execute-remote-commands.html) to run the `AWSFIS-Run-Cpu-Stress` command document against our targets for two minutes.

### Target selection

For this action we need to designate EC2 instance targets on which to run the commands. Go to the “Targets” section, select the `Instances-Target-1` section, and select **“Edit”**.

You may leave the default name `Instances-Target-1` but for maintainability we rcommend using descriptive target names. Change the name to `FisWorkshop-StressLinux` (this will automatically update the name in the action as well) and make sure “Resource type” is set to `aws:ec2:instances`. To select our target instances by tag select "Resource tags and filters" and keep selection mode `ALL`. Select **"Add new tag"** and enter a "Key" of `Name` and a "Value" of `FisLinuxCPUStress`. Finally select **"Save"**. 

{{< img "EditTarget-rev1.png" "Target Settings" >}}

### Creating template without stop conditions

Select **"Create experiment template"** and confirm that you wish to create a template without stop conditions.


## Validation procedure

We will use the linux `top` system command to observe the increased CPU load. To do this we now need to connect to our EC2 Instance so we can observe the CPU being stressed. Head over to the [**EC2 Console**](https://console.aws.amazon.com/ec2/v2/home?#Instances:instanceState=running). 

1. Once at the EC2 Console lets select our instance named `FisLinuxCpuStress` and click on the "Connect" button. 

{{< img "SelectConnect-rev1.png" "Select Instance" >}}

2. Select **"Session Manager"** and select **"Connect"**.

{{< img "SessionManagerConnect.png" "Connect to EC2" >}}

This will open a session to the EC2 instance in another tab. In the new tab enter:

```bash
top
```

You should now see a continuously updating display similar to the next screenshot. Initially the CPU percentage should be at or close to zero as this instance is not doing anything. Keep this tab open, we will come back once we have started our experiment. 

{{< img "LinuxNoStress.png" "CPU Not Stressed" >}}

## Run CPU Stress Experiment

{{% notice note %}}
We are assuming that you know how to set up a basic FIS experiment and will focus on things specific to this experiment. If you need a refresher see the previous [**First Experiment**]({{< ref "030_basic_content/030_basic_experiment/" >}}) section.
{{% /notice %}}

Keep the EC2 instance session with `top` running. In a new browser window navigate to the [**AWS Fault Injection Simulator Console**](https://console.aws.amazon.com/fis/home?#Home) and start the experiment:

* use the `LinuxBurnCPUviaSSM`
* add a `Name` tag of `FisWorkshopLinuxStress1`
* confirm that you want to start the experiment
* ensure that the "State" is `Running`

{{< img "RunningState.png" "Experiment State" >}}

In the EC2 terminal window watch the CPU percentage displayed by `top`: it should hit 100% for a few minutes and then return back to 0%. Once we have observed the action we can click the `Terminate` button to terminate our Session Manager session. 

{{< img "linuxStressed.png" "Linux Stressed" >}}

Congratulations for completing this lab! In this lab you walked through running an experiment that took action within a Linux EC2 Instance using AWS Systems Manager.  Using the integration between Fault Injection Simulator and AWS Systems Manager you can run scripted actions within an EC2 Instance. Through this integration you can script events against your applications or run other chaos engineering tools and frameworks. 

## Learning and improving

Since this instance wasn't doing anything, there aren't any actions. To think about how to use this to test a hypothesis and make an improvement, consider running the same experiment against the ASG instances from the [**First Experiment**]({{< ref "030_basic_content/030_basic_experiment" >}}) section. Maybe you could use this to tune the optimal CPU levels for scaling up or down?


