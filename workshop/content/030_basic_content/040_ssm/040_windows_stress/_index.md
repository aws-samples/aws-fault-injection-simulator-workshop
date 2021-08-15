+++
title = "Windows CPU Stress Experiment"
weight = 40
+++

{{% notice warning %}}
This section requires that you have an RDP client on your local machine. This section cannot be performed from a cloud9 instance. 
{{% /notice %}}

In this section we will run a CPU Stress test using AWS Fault Injection Simulator against an Amazon Windows EC2 Instance. The Windows CPU stress test will use a custom SSM command document. We will do the following: 

1. Create experiment template to stress CPU.
2. Reset password on Windows Instance.
2. Connect to Windows EC2 Instance and run task manager.
3. Start experiment and observe results.

## Experiment Setup 

### Create CPU Stress Experiment

First, lets create our stress experiment. We can do this programmatically but we will walk through this on the console. 

1. Open the [AWS Fault Injection Simulator Console](https://console.aws.amazon.com/fis/home?#Home). Once in the Fault Injection Simulator console, lets click on "Experiment templates" on the left side pane. 

2. Click on "Create experiment template" on  the upper right hand side of the console to start creating our experiment template. 

3. Next we will enter the description of the experiment and choose the IAM Role. Let's put `WindowsBurnCPUviaSSM` for the description. The IAM role allows the FIS service permissions to execute the actions on your behalf. As part of the CloudFormation stack a role was created for this experiment that starts with `FisCpuStress-FISRole`, select that role. Please examine the CloudFormation template or IAM Role for the policies in this role. 

{{< img "Winexperimentdescription.png" "Win Experiment Description and Role" >}}

4. After we have entered a description and a role, we need to setup our actions. Click the "Add action" button in the Actions Section. 

Enter a "Name" of `StressCPUViaSSM`, and under "Action Type" select the `aws:ssm:send-command` action. Currently there is not an out of box Action for Windows CPU Stress Testing, so we are using the send-command action along with a command document that was deployed by our CloudFormation template. To view this document please reference the `WinStressDocument` resource in the [CloudFormation template](https://github.com/aws-samples/aws-fault-injection-simulator-workshop/blob/main/resources/templates/cpu-stress/CPUStressInstances.yaml). 

To find the ARN of the document that was created by the template, open a new tab and browse to the [CloudFormation console](https://console.aws.amazon.com/cloudformation/home?#/stacks?filteringStatus=active&filteringText=FisCpuStress&viewNested=true&hideStacks=false), select "Stacks", click on the stack named "FisCpuStress", then select "Outputs". Copy the value of the `WinStressDocumentArn` entry as you will need it in the next step.

Return to the FIS console and enter the ARN you copied into the "documentArn" field. Then set the "documentParameters" field to `{"durationSeconds":120}` which is passed to the script and the "duration" field to `2` which tells FIS how long to wait for a result. Finally click "Save". This action will use [AWS Systems Manager Run Command](https://docs.aws.amazon.com/systems-manager/latest/userguide/execute-remote-commands.html) to run the `FisCpuStress-WinStressDocument` document against our targets for two minutes. 

{{< img "WinStressActionSettings.png" "Action Settings" >}}

5. Once we have saved the action, let's edit our targets. Click on "Edit" button under the Targets section. To select our target instances by tag select "Resource tags and filters" and keep selection mode `ALL`. Click "Add new tag" and enter a "Key" of `Name` and a "Value" of `FisWindowsCPUStress`. Finally click "Save". 

{{< img "WinEditTarget.png" "Target Settings" >}}

6. Once we have actions and targets specified we can click on the "Create Experiment" button toward the bottom of the console to create our template. 

**_Note:_** For this experiment we did not assign a stop condition, for a workshop or lab this is acceptable. However, it would be considered best practice to have stop conditions on your experiments so they don't go out of bounds. Because we do not have a stop condition we are being asked to confirm creation of this experiment. Type in `create` and then hit the "Create Experiment" button again to confirm. 

{{< img "ConfirmCreate.png" "Confirm Creation" >}}

We have created our Windows CPU stress experiment template, now lets connect to our EC2 Instance.

## Validation procedure

We will use the Windows task manager to observe increased CPU load. To do this we now need to connect to our EC2 Instance so we can observe the CPU being stressed. 

### Use AWS Systems Manager Run Command to reset Password

When we deployed the instance we didn't use SSH Keys, and we don't know the password. However, with the SSM Agent along with the right IAM privileges we have a break glass scenario where we can reset the password. Please adjust the value of `TMP_PASSWORD` and use the commands below to find the InstanceId of the `FisWindowsCPUStress` instance and help you reset the admin password to the password of choice. 

```bash
# For readability - passing passwords this way is not secure
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

### Use AWS Systems Manager Session Manager to connect to Target Instance

We now need to connect to our EC2 Instance so we can observe the CPU being stressed. We are going to do this by using the port forwarding capability of AWS Systems Manager Session Manager and using RDP.

1. Run the following command first, this will forward local port 56788 to port 3389 on the Windows EC2 Instance. Replace the **<instanceid>** with the instance ID of the Windows Instance.

    ```bash
    # This presumes you set TMP_INSTANCE (see above)
    aws ssm start-session --target ${TMP_INSTANCE} --document-name AWS-StartPortForwardingSession --parameters '{"portNumber":["3389"],"localPortNumber":["56788"]}'
    ```

2. Once the command says waiting for connections you can launch the RDP client and enter `localhost:56788` for the server name and login as `administrator` with the password you set in the previous section. 

    {{% expand "Troubleshooting connectivity" %}}
When running the `start-session` command above, you may get a message about a missing session manager plugin. If you do, follow the [link in the message](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html) and install the plugin.

The second likely issue you are going to run into is a failed password reset, e.g. because your password did not meet the complexity criteria. To verify that the password reset succeeded, navigate to the [AWS Systems Manager Run Command console](https://console.aws.amazon.com/systems-manager/run-command/executing-commands), select "Command history", and locate the `AWS-RunPowerShellScript` that you executed above. If in doubt compare the `CommandId` value from the CLI invocation with the "Command ID" value on the console.

{{< img "run-command-history-1.en.png" "Run command history" >}}

Click on the command ID link, then on the instance id:

{{< img "run-command-history-2.en.png" "Instance for history" >}}

Then examine the Error output:

{{< img "run-command-history-3.en.png" "Error output for command" >}}


    {{% /expand %}}



3. Once you have RDP'ed into the Windows Instance, launch task manager by right clicking on the menu bar and selecting "Task Manager". Click on "More details" button and then on the "Performance" tab so you can see the CPU graph as shown below. 

{{< img "WinNoStress.png" "Task Manager" >}}


## Run CPU Stress Experiment

Let's head back to the [AWS Fault Injection Simulator Console](https://console.aws.amazon.com/fis/home?#Home).

1. Once in the Fault Injection Simulator console, lets click on "Experiment templates" again on the left side pane. 

2. Select the experiment with the `WindowsBurnCPUviaSSM` description, then click on the "Actions" button and select "Start". This will allow us to enter additional tags before starting our experiment. Then click on the "Start experiment" button. 

3. Next type in `start` and click on "Start Experiment" again to confirm you want to start the experiment. 

{{< img "confirmstart.png" "Confirm Start" >}}

This will take you to the running experiment that is started from the template. In the detail section of the experiment check `State` and you should see the experiment is initializing. Once the experiment is running, lets go back to the RDP session and observe the task manager graph. 

Watch the CPU percentage, it should hit 100% for a few minutes and then return back to 0%. Once we have observed the action we can logout of the Windows Instance and hit CTRL + C on the window you ran the port forwarding command to close the session. 
 
{{< img "WindowsStressed.png" "Windows Stressed" >}}

## Learning and improving

Congrats for completing this lab! In this lab you walked through running an experiment that took action within a Windows EC2 Instance using AWS Systems Manager and a custom run command.  Using the integration between Fault Injection Simulator and AWS Systems Manager you can run scripted actions within an EC2 Instance. Through this integration you can script events against your applications or run other chaos engineering tools and frameworks. 

Since this instance wasn't doing anything there aren't any actions. To think about how to use this to test a hypothesis and make an improvement consider building custom SSM scripts to run custom scenarios. We will cover some of these in the **Common Scenarios** section.

## Cleanup

If you created an additional `CpuStress` CloudFormation stack in the **FIS SSM Setup** section, make sure to delete that stack to avoid incurring additional costs.

