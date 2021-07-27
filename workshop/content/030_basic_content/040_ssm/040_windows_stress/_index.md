+++
title = "Windows CPU Stress Experiment"
date =  2021-07-07T17:25:37-06:00
weight = 40
+++

{{% notice warning %}}
This section requires that you have an RDP agent on your local machine. This section cannot be performed from a cloud9 instance. 
{{% /notice %}}

In this section we will run a CPU Stress test using AWS Fault Injection Simulator against an Amazon Windows EC2 Instance. The Windows CPU stress test will use a custom SSM command document. We will do the following: 

1. Create experiment template to stress CPU.
2. Reset password on Windows Instance
2. Connect to Windows EC2 Instance and run task manager.
3. Start experiment and observe results.

## Experiment Setup 

### Create CPU Stress Experiment

First, lets create our stress experiment. We can do this programmaticaly but we will walk through this on the console. 

1. Open the [AWS Fault Injection Simulator Console](https://console.aws.amazon.com/fis/home?#Home).Once in the Fault Injection Simulator console, lets click on **Experiment templates** on the left side pane. 

2. Click on **Create Experiment** on  the upper right hand side of the console to start creating our experiment template. 

3. Next we will enter the description of the experiment and choose the IAM Role. Let's put **WindowsBurnCPUviaSSM** for the description. The IAM role allows the FIS service permissions to execute the actions on your behalf. As part of the CloudFormation stack a role was created for this experiment that starts with **CpuStress-FISRole**, select that role. Please Examine the CloudFormation template or IAM Role for the policies in this role. 

{{< img "Winexperimentdescription.png" "Win Experiment Description and Role" >}}

4. After we have entered a description and a role, we need to setup our actions. Click the **Add Action** Button in the Actions Section. 

Name the Action, and under Action Type select the **aws:ssm:send-command** action. Currently there is not an out of box Action for Windows CPU Stress Testing, so we are using the send-command action along with a command document that was deployed by our CloudFormation template. To view this document please reference the WinStressDocument resource in the CloudFormation Template.  

Match the rest of the settings as seen in the next screenshot and then click **Save**. This action will use [AWS Systems Manager Run Command](https://docs.aws.amazon.com/systems-manager/latest/userguide/execute-remote-commands.html) to run the CpuStress-WinStressDocument document against our targets for two minutes. To get the document ARN look out that output section of the CloudFormation Stack we deployed for this lab. 

{{< img "WinStressActionSettings.png" "Action Settings" >}}

5. Once we have saved the action, let's edit our targets. Click on **Edit targets**. We are going to target our Instances by tag. Match the settings in the next screenshot and click **Save**. 

{{< img "WinEditTarget.png" "Target Settings" >}}

6. Once we have actions and targets specified we can click on the **Create Experiment** button toward the bottom of the console to create our template. 

**_Note:_** For this experiment we did not assign a stop condition, for a workshop or lab this is acceptable. However, it would be considered best practice to have stop conditions on your experiemnts so they dont go out of bounds. Because we do not have a stop condition we are being asked to confirm creation of this experiment. Type in *create* and then hit the **Create Experiment** button again to confirm. 

{{< img "ConfirmCreate.png" "Confirm Creation" >}}

We have created our Windows CPU stress experiment template, now lets connect to our EC2 Instance.

## Validation procedure

We will use the Windows task manager to observe increased CPU load. To do this we now need to connect to our EC2 Instance so we can observe the CPU being stressed. 

### Use AWS Systems Manager Run Command to reset Password

When we deployed the instance we didnt use SSH Keys, and we dont know the password. However, with the SSM Agent along with the right IAM privileges we have a break glass scenario where we can reset the password. Please use the command below, replacing the **instanceid** with the `FisWindowsCPUStress` instance ID and **password** with your password of choice. 

```bash
# For readbility - passing passwords this way is not secure
TMP_PASSWORD=ENTER_NEW_PASSWORD_HERE
```

```bash
# For readability and convenience
TMP_INSTANCE=$(  aws ec2 describe-instances --filter Name=tag:Name,Values=FisWindowsCPUStress --query 'Reservations[*].Instances[0].InstanceId' --output text )

# Reset password on instance - this is not a secure method, 
# in real life use AWS-PasswordReset document
aws ssm send-command \
  --document-name "AWS-RunPowerShellScript" \
  --document-version "1" \
  --targets '[{"Key":"InstanceIds","Values":["'${TMP_INSTANCE}'"]}]' --parameters '{"workingDirectory":[""],"executionTimeout":["3600"],"commands":["net user administrator '${TMP_PASSWORD}'"]}' \
  --timeout-seconds 600 \
  --max-concurrency "50" \
  --max-errors "0" \
  --cloud-watch-output-config '{"CloudWatchOutputEnabled":false}'
```

### Use AWS Systems Session Manager to connect to Target Instance

We now need to connect to our EC2 Instance so we can observe the CPU being stressed. We are going to do this be using the port forwarding capability of AWS Systems Manager Session Manager and using RDP.

1. Run the following command first, this will forward local port 56788 to port 3389 on the Windows EC2 Instance. Replace the **<instanceid>** with the instance ID of the Windows Instance.

    ```bash
    # This presumes you set TMP_INSTANCE (see above)
    aws ssm start-session --target ${TMP_INSTANCE} --document-name AWS-StartPortForwardingSession --parameters '{"portNumber":["3389"],"localPortNumber":["56788"]}'
    ```

2. Once the command says waiting for connections you can launch the RDP client and enter `localhost:56788` for the server name and login as `administrator` with the password you set in the previous section. 

    {{% expand "Troubleshooting connectivity" %}}
When running the `start-session` command above, you may get a message about a missing session manager plugin. If you do follow the [link in the message](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html) and install the plugin.

The second likely issue you are going to run into is a failed password reset, e.g. because your password did not meet the complexity criteria. To verify that password reset succeeded, navigate to the [AWS Systems Manager Run Command console](https://console.aws.amazon.com/systems-manager/run-command/executing-commands), select "Command history", and locate the `AWS-RunPowerShellScript` that you executed above. If in doubt compare the `CommandId` value from the CLI invocation with the "Command ID" value on the console.

{{< img "run-command-history-1.en.png" "Run command history" >}}

Click on the command ID link, then on the 

{{< img "run-command-history-2.en.png" "Instance for history" >}}

Then examine the Error output:

{{< img "run-command-history-3.en.png" "Error output for command" >}}


    {{% /expand %}}



3. Once you have RDP'ed into the Windows Instance, launch task manager so you can see the CPU graph as shown below. 

{{< img "WinNoStress.png" "Task Manager" >}}


## Run CPU Stress Experiment

Let's head back to the [AWS Fault Injection Simulator Console](https://console.aws.amazon.com/fis/home?#Home).

1. Once in the Fault Injection Simulator console, lets click on Experiment templates again on the left side pane. 

2. Select the experiment with the WindowsBurnCPUviaSSM description, then click on the **Actions** button and select **Start Experiment**. Now click on the **Start Experiment** button. 

3. Next type in start and click on **Start Experiment** again to confirm you want to start the experiment. 
{{< img "confirmstart.png" "Confirm Start" >}}

This will take you to the running experiment, in the detail section of the experiment under state you should see the experiment is initializing. Once the experiment is running, lets go back to the RDP session and observe the task manager graph. 

Watch the CPU percentage, it should hit 100% for a few minutes and then return back to 0%. Once we have observed the action we can logout of the Windows Instance and hit CTRL + C on the window you ran the port forwarding command to close the session. 
 
{{< img "WindowsStressed.png" "Windows Stressed" >}}

## Learning and improving

Congrats for completing this lab! In this lab you walked through running an experiment that took action within a Windows EC2 Instance using AWS Systems Manager and a custom run command.  Using the integration between Fault Injection Simulator and AWS Systems Manager you can run scripted actions within an EC2 Instance. Through this integration you can script events against your applications or run other choas engineering tools and frameworks. 

Since this instance wasn't doing anything there aren't any actions. To think about how to use this to test a hypothesis and make an improvement consider building custom SSM scripts to run custom scenarios. We will conver some of these in the **Common Scenarios** section.

## Cleanup

If you created an additional `CpuStress` CloudFormation stack in the **FIS SSM Setup** section, make sure to delete that stack.
