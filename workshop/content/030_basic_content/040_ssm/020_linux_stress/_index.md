+++
title = "Linux CPU Stress Experiment"
weight = 20
+++

In this section we will run a CPU Stress test using AWS Fault Injection Simulator against an Amazon Linux EC2 Instance. The Linux [CPU stress](https://docs.aws.amazon.com/fis/latest/userguide/actions-ssm-agent.html#fis-ssm-docs) test is an out of the box FIS action. We will do the following: 

1. Create experiment template to stress CPU.
2. Connect to a Linux EC2 Instance and run the Top Command.
3. Start experiment and observe results.

## Experiment Setup

### Create CPU Stress Experiment Template

First, lets create our stress experiment. We can do this programmatically but we will walk through this on the console. 

1. Open the [AWS Fault Injection Simulator Console](https://console.aws.amazon.com/fis/home?#Home). Once in the Fault Injection Simulator console, lets click on "Experiment templates" on the left side pane. 

2. Click on "Create Experiment Template" on  the upper right hand side of the console to start creating our experiment template. 

3. Next we will enter the description of the experiment and choose the IAM Role. Let's put `LinuxBurnCPUviaSSM` for the description. The IAM role allows the FIS service permissions to execute actions on your behalf. As part of the CloudFormation stack a role was created for this experiment that starts with `FisCpuStress-FISRole`, select that role. Please examine the CloudFormation template or IAM Role for the policies in this role. 

{{< img "experimentdescription.png" "Linux Experiment Description and Role" >}}

4. After we have entered a description and a role, we need to setup our actions. Click on the "Add Action" button in the Actions section. 

Name the Action as `StressCPUViaSSM` and under *Action Type* select `aws:ssm:send-command/AWSFIS-Run-Cpu-Stress`. This is an out of the box action to run stress test on Linux Instances using the stress-ng tool. Set the "documentParameters" field to `{"DurationSeconds":120}` which is passed to the script and the "duration" field to `2` which tells FIS how long to wait for a result. Finally click "Save". This action will use [AWS Systems Manager Run Command](https://docs.aws.amazon.com/systems-manager/latest/userguide/execute-remote-commands.html) to run the AWSFIS-Run-Cpu-Stress command document against our targets for two minutes.

{{< img "StressActionSettings.png" "Action Settings" >}}

5. Once we have saved the action, let's edit our targets. Click on "Edit" button under the Targets section. To select our target instances by tag select "Resource tags and filters" and keep selection mode `ALL`. Click "Add new tag" and enter a "Key" of `Name` and a "Value" of `FisLinuxCPUStress`. Finally click "Save". 

{{< img "EditTarget.png" "Edit Targets" >}}

6. Once we have actions and targets specified we can click on the "Create Experiment" button toward the bottom of the console to create our template. 

**_Note:_** For this experiment we did not assign a stop condition, for a workshop or lab this is acceptable. However, it would be considered best practice to have stop conditions on your experiments so they don't go out of bounds. Because we do not have a stop condition we are being asked to confirm creation of this experiment. Type in `create` and then hit the "Create Experiment" button again to confirm. 

{{< img "ConfirmCreate.png" "Confirm Creation" >}}

We have created our Linux CPU stress experiment template, now lets connect to our EC2 Instance.

## Validation procedure

We will use the linux `top` system command to observe the increased CPU load. To do this we now need to connect to our EC2 Instance so we can observe the CPU being stressed. Head over to the [EC2 Console](https://console.aws.amazon.com/ec2/v2/home?#Instances:instanceState=running). 

1. Once at the EC2 Console lets select our instance named `FisLinuxCpuStress` and click on the "Connect" button. 

{{< img "SelectConnect.png" "Select Instance" >}}

2. Select "Session Manager" and click on "Connect".

{{< img "SessionManagerConnect.png" "Connect to EC2" >}}

This will open a session to the EC2 instance in another tab. In the new tab enter:

```bash
top
```

You should now see a continuously updating display similar to the next screenshot. Initially the CPU percentage should be at or close to zero as this instance is not doing anything. Keep this tab open, we will come back once we have started our experiment. 

{{< img "LinuxNoStress.png" "CPU Not Stressed" >}}

## Run CPU Stress Experiment

Let's head back to the [AWS Fault Injection Simulator Console](https://console.aws.amazon.com/fis/home?#Home).

1. Once in the Fault Injection Simulator console, lets click on "Experiment templates" again on the left side pane. 

2. Select the experiment template with the `LinuxBurnCPUviaSSM` description, then click on the "Actions" button and select "Start". This will allow us to enter additional tags before starting our experiment. Then click on the "Start Experiment" button. 

3. Next type in `start` and click on "Start Experiment" again to confirm you want to start the experiment. 

{{< img "confirmstart.png" "Confirm Start" >}}

This will take you to the running experiment that is started from the template. In the detail section of the experiment check `State` and you should see the experiment is initializing. Once the experiment is running, lets head back to the open session on the EC2 Instance. 

{{< img "RunningState.png" "Experiment State" >}}

Watch the CPU percentage, it should hit 100% for a few minutes and then return back to 0%. Once we have observed the action we can click the `Terminate` button to terminate our Session Manager session. 

{{< img "linuxStressed.png" "Linux Stressed" >}}

Congrats for completing this lab! In this lab you walked through running an experiment that took action within a Linux EC2 Instance using AWS Systems Manager.  Using the integration between Fault Injection Simulator and AWS Systems Manager you can run scripted actions within an EC2 Instance. Through this integration you can script events against your applications or run other chaos engineering tools and frameworks. 

## Learning and improving

Since this instance wasn't doing anything there aren't any actions. To think about how to use this to test a hypothesis and make an improvement consider running the same experiment against the ASG instances from the **First Experiment** section. Maybe you could use this to tune the optimal CPU levels for scaling up or down?


