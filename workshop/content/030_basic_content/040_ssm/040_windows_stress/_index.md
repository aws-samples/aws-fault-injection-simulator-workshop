+++
title = "Windows CPU Stress Experiment"
weight = 40
+++

{{% notice warning %}}
This section requires that you have an RDP client on your local machine. This section cannot be performed from a cloud9 instance. 
{{% /notice %}}

## Experiment idea

In this section we are exploring tooling so we will start without a hypothesis. However, we will provide some learnings and next steps at the end.

Specifically, in this section we will run a CPU Stress test using AWS Fault Injection Simulator against an Amazon Windows EC2 Instance. The Windows CPU stress test will use a custom SSM command document. We will do the following: 

1. Create experiment template to stress CPU.
2. Reset password on Windows Instance.
2. Connect to Windows EC2 Instance and run task manager.
3. Start experiment and observe results.

## Experiment Setup 

{{% notice note %}}
We are assuming that you know how to set up a basic FIS experiment and will focus on things specific to this experiment. If you need a refresher see the previous [**First Experiment**]({{< ref "030_basic_content/030_basic_experiment/" >}}) section.
{{% /notice %}}

### General template setup

* Create a new experiment template
  * Add a name for the template using a Tag with key as `Name` and value as `WindowsBurnCPUviaSSM` (located at bottom of page)
  * Add `Description` of `Inject CPU stress on Windows`
  * Select `FisCpuStress-FISRole` as execution role

### Action definition 

In the "Actions" section select the **"Add Action"** button. 

"Name" the action as `StressCPUViaSSM`, and under "Action Type" select the `aws:ssm:send-command` action. Currently there is no out of box Action for Windows CPU Stress Testing, so we are using the send-command action along with a command document that was deployed by our CloudFormation template. To view this document please reference the `WinStressDocument` resource in the [**CloudFormation template**](https://github.com/aws-samples/aws-fault-injection-simulator-workshop/blob/main/resources/templates/cpu-stress/CPUStressInstances.yaml). 

To find the ARN of the document that was created by the template, open a new tab and browse to the [**CloudFormation console**](https://console.aws.amazon.com/cloudformation/home?#/stacks?filteringStatus=active&filteringText=FisCpuStress&viewNested=true&hideStacks=false), select **"Stacks"**, select the stack named **"FisCpuStress"**, then select **"Outputs"**. Copy the value of the `WinStressDocumentArn` entry as you will need it in the next step.

Return to the FIS console and enter the ARN you copied into the "documentArn" field. Then set the "documentParameters" field to `{"durationSeconds":120}` which is passed to the script and the "duration" field to `2` minutes which tells FIS how long to wait for a result. Leave the default “Target” `Instances-Target-1` and  select **"Save"**. 

{{< img "WinStressActionSettings.png" "Action Settings" >}}

This action will use [**AWS Systems Manager Run Command**](https://docs.aws.amazon.com/systems-manager/latest/userguide/execute-remote-commands.html) to run the `FisCpuStress-WinStressDocument` document against our targets for two minutes. 

### Target selection

For this action we need to designate EC2 instance targets on which to run the commands. Go to the “Targets” section, select the `Instances-Target-1` section, and select **“Edit”**.

You may leave the default name `Instances-Target-1` but for maintainability we rcommend using descriptive target names. Change the name to `FisWorkshop-StressWindows` (this will automatically update the name in the action as well) and make sure “Resource type” is set to `aws:ec2:instances`. To select our target instances by tag select "Resource tags and filters" and keep selection mode `ALL`. Select **"Add new tag"** and enter a "Key" of `Name` and a "Value" of `FisWindowsCPUStress`. Finally select **"Save"**. 

{{< img "WinEditTarget-rev1.png" "Target Settings" >}}

### Creating template without stop conditions

Select **"Create experiment template"** and confirm that you wish to create a template without stop conditions.

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

1. First make sure that the [**Session Manager plugin for the AWS CLI**](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html) is installed on your local machine.
2. Run the following command first, this will securely forward local port 56788 to port 3389 on the Windows EC2 Instance. Note that we are targeting a specific instance by passing the `TMP_INSTANCE` variable from above.

    ```bash
    # This presumes you set TMP_INSTANCE (see above)
    aws ssm start-session --target ${TMP_INSTANCE} --document-name AWS-StartPortForwardingSession --parameters '{"portNumber":["3389"],"localPortNumber":["56788"]}'
    ```

3. Once the command says `waiting for connections` you can launch the RDP client and enter `localhost:56788` for the server name and login as `administrator` with the password you set in the previous section. 

    {{% expand "Troubleshooting connectivity" %}}
When running the `start-session` command above, you may get a message about a missing session manager plugin. If you do, follow the [**link in the message**](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html) and install the plugin.

The second likely issue you are going to run into is a failed password reset, e.g. because your password did not meet the complexity criteria. To verify that the password reset succeeded, navigate to the [**AWS Systems Manager Run Command console**](https://console.aws.amazon.com/systems-manager/run-command/executing-commands), select "Command history", and locate the `AWS-RunPowerShellScript` that you executed above. If in doubt compare the `CommandId` value from the CLI invocation with the "Command ID" value on the console.

{{< img "run-command-history-1.en.png" "Run command history" >}}

Click on the command ID link, then on the instance id:

{{< img "run-command-history-2.en.png" "Instance for history" >}}

Then examine the Error output:

{{< img "run-command-history-3.en.png" "Error output for command" >}}


    {{% /expand %}}



4. Once you have RDP'ed into the Windows Instance, launch task manager by right clicking on the menu bar and selecting "Task Manager" (or by using the SHIFT-CTRL-ESC keyboard sortcut). Click on **"More details"** button and then on the **"Performance"** tab so you can see the CPU graph as shown below. 

{{< img "WinNoStress.png" "Task Manager" >}}

## Run CPU Stress Experiment

{{% notice note %}}
We are assuming that you know how to set up a basic FIS experiment and will focus on things specific to this experiment. If you need a refresher see the previous [**First Experiment**]({{< ref "030_basic_content/030_basic_experiment/" >}}) section.
{{% /notice %}}

Keep the RDP session with "Task Manager" running. In a new browser window navigate to the [**AWS Fault Injection Simulator Console**](https://console.aws.amazon.com/fis/home?#Home) and start the experiment:

* use the `WindowsBurnCPUviaSSM`
* add a `Name` tag of `FisWorkshopWindowsStress1`
* confirm that you want to start the experiment
* ensure that the "State" is `Running`

Once the experiment is running, lets go back to the RDP session and observe the task manager graph. 

Watch the CPU percentage, it should hit 100% for a few minutes and then return back to 0%. Once we have observed the action we can logout of the Windows Instance and hit CTRL + C on the window you ran the port forwarding command to close the session. 
 
{{< img "WindowsStressed.png" "Windows Stressed" >}}

Congratulations for completing this lab! In this lab you walked through running an experiment that took action within a Windows EC2 Instance using AWS Systems Manager and a custom run command.  Using the integration between Fault Injection Simulator and AWS Systems Manager you can run scripted actions within an EC2 Instance. Through this integration you can script events against your applications or run other chaos engineering tools and frameworks. 

## Learning and improving

Since this instance wasn't doing anything there aren't any actions. To think about how to use this to test a hypothesis and make an improvement consider building custom SSM scripts to run custom scenarios. We will cover some of these in the [**Common Scenarios**]({{< ref "030_basic_content/090_scenarios" >}}) section.

## Cleanup

If you created an additional `CpuStress` CloudFormation stack in the [**FIS SSM Setup**]({{< ref "030_basic_content/040_ssm/010_setup" >}}) section, make sure to delete that stack to avoid incurring additional costs.

