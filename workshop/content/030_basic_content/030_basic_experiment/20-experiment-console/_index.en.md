---
title: "Experiment (Console)"
weight: 20
services: true
---

In this section, we will learn how to create an AWS FIS experiment template using the AWS Console. 

## Experiment setup

To create a fault injection experiment, we first need to create an AWS FIS template defining:

* Name (optional)
* Description (optional)
* Template permissions
* [**Actions**](https://docs.aws.amazon.com/fis/latest/userguide/actions.html)
* [**Targets**](https://docs.aws.amazon.com/fis/latest/userguide/targets.html)
* [**Stop Conditions**](https://docs.aws.amazon.com/fis/latest/userguide/stop-conditions.html) (optional but strongly recommended)
* Tags

### Create an AWS FIS experiment template

Navigate to the [**FIS console**](https://console.aws.amazon.com/fis/home?#Home) and select **"Create experiment template"**.

{{< img "create-template-1.en.png" "AWS FIS console" >}}

{{% notice note %}}
**_Note:_** if you've used AWS FIS before you may not see the splash screen. In that case select "Experiment templates" in the burger menu on the left and access **"Create experiment template"** from there.
{{% /notice %}}

#### Template description, name, and permissions

Let's write a description for our experiment template and select an IAM role to use when performing the experiment. Go to the "Description, name and permission" section. For "Description" enter `Terminate half of the instances in the auto scaling group`, for "Name" enter `FisWorkshopExp1Run1` and for "IAM Role" select the `FisWorkshopServiceRole` role you created previously.

{{< img "create-template-2-description.en.png" "Set FIS description and role" >}}

#### Action definition

Here we select the type of fault we wish to inject, the action to take. To test the hypothesis that we can safely impact half the instances in our Auto Scaling group, we will terminate those instances. Go to the "Actions" section and select **"Add Action"**.

{{< img "create-template-2-actions-1.en.png" "Add FIS actions" >}}

For "Name" enter `FisWorkshopAsg-TerminateInstances` and add a "Description" like `Terminate instances`. For "Action type" select `aws:ec2:terminate-instances`.

We will leave the "Start after" section blank since we are only taking a single action in this experiment template. 


Leave the default "Target" `Instances-Target-1` and select **"Save"**.

{{< img "create-template-2-actions-2-autogen.en.png" "Edit FIS actions" >}}

{{% notice note %}}
`Instances-Target-1` was auto-generated for us because no appropriate target type existed in the experiment template. If one or more targets already exist, e.g. because we added actions before, then we will be presented with a drop down selector for existing targets instead.
{{% /notice %}}

#### Target definition

For our action we are choosing to terminate EC2 instances. In the target section we define which instances to terminate. As a reminder, for this first experiment we want to prove the hypothesis that we can safely impact half the instances in our Auto Scaling group. 

Go to the "Targets" section, select the `Instances-Target-1` section, and select **"Edit"**.

{{< img "create-template-2-targets-1-autogen.en.png" "Add FIS target" >}}

You may leave the default name `Instances-Target-1` but for maintainability we rcommend using descriptive target names. Change the name to `FisWorkshopAsg-50Percent` (this will automatically update the name in the action as well) and make sure "Resource type" is set to `aws:ec2:instances`. For "Target method" we will dynamically select resources based on an associated tag. Select the `Resource tags and filters` checkbox. Pick `Percent` from "Selection mode" and enter `50`. Under "Resource tags" enter `Name` in the "Key" field and `FisStackAsg/ASG` for "Value" to select only from instances associated with the desired Auto Scaling group. Under filters enter `State.Name` in the "Attribute path" field and `running` under "Values" to ensure we do not consider instances that are starting or stopping due to unrelated events. For more information on filters see the [**documentation**](https://docs.aws.amazon.com/fis/latest/userguide/targets.html#target-identification). Select **"Save"**.

{{< img "create-template-2-targets-2.en.png" "Edit FIS target" >}} 

#### Stop conditions

AWS FIS provides stop conditions tied to [**Amazon CloudWatch alarms**](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/AlarmThatSendsEmail.html) as a safeguard to minimize the impact of experiments that do not perform as expected. In this experiment we are performing a single action that cannot be reverted so we will leave this empty.

{{< img "create-template-4-stop-conditions-empty.en.png" "Skip Stop Condition section" >}} 


#### Logs

To write logs of FIS events to CloudWatch, expand the "Logs" card, check the "Send to CloudWatchLogs" checkbox, and select "Browse" to select the pre-created log group:

{{< img "create-template-5-logs-1.en.png" "Enable CloudWatch logging for FIS" >}} 

For "Log groups" enter `/fis-workshop/fis-logs` and select the relevant entry: 

{{< img "create-template-5-logs-2.en.png" "Browse for log group" >}} 


#### Template tags

AWS FIS tracks the template name as the special tag `Name` which is displayed in the "Name" field of the experiment template list view. In addition to the Name tag that propagated from setting it in the "Description, name and permission" card, we can optionally attach tags to our template. Tags can be used in IAM policy [**condition keys**](https://docs.aws.amazon.com/service-authorization/latest/reference/list_awsfaultinjectionsimulator.html#awsfaultinjectionsimulator-fis_Service) to control access to the experiment template. 

For this experiment we will make no changes here.

{{< img "create-template-2-name.en.png" "Set FIS template name" >}}


#### Creating template without stop conditions

Scroll to the bottom of the template definition page and select *"Create experiment template"*. 

Since we didn't specify a stop condition we receive a warning. This is ok, for this experiment we won't use a stop condition. Type `create` in the text box as indicated and select **"Create experiment template"**.

{{< img "create-template-3-confirm.en.png" "Confirm and save FIS template" >}}





## Validation procedure

We will be using the AWS CloudWatch dashboard from the previous sections for validation, no additional setup required.

## Run FIS experiment

As [**previously discussed**]({{< ref "030_basic_content/010-baselining" >}}), we should collect both customer and ops metrics. For larger experiments we would add the load generator into our experiment.

However, for this experiment we will manually trigger load generation on the system before starting the experiment, similar to what we did in the previous section. Here we have increased the run time to 5 minutes by setting `ExperimentDurationSeconds` to `300`:

```bash
# Please ensure that LAMBDA_ARN, URL_HOME, and FIX_CLI_PARAM are still set from previous section

# Run load for 5min, 3x in parallel because max per lambda is 1000
for ii in 1 2 3; do
  aws lambda invoke \
    --function-name ${LAMBDA_ARN} \
    --payload "{
          \"ConnectionTargetUrl\": \"${URL_PHP}\", 
          \"ExperimentDurationSeconds\": 300,
          \"ConnectionsPerSecond\": 1000,
          \"ReportingMilliseconds\": 1000,
          \"ConnectionTimeoutMilliseconds\": 2000,
          \"TlsTimeoutMilliseconds\": 2000,
          \"TotalTimeoutMilliseconds\": 2000
      }" \
    $FIX_CLI_PARAM \
    --invocation-type Event \
    /dev/null
done
```

{{% notice warning %}}
If you are running AWS CLI v2, you need to pass the parameter `--cli-binary-format raw-in-base64-out` or you'll get the error "Invalid base64" when sending the payload.
{{% /notice %}}

To start the experiment navigate to the [**FIS console**](https://console.aws.amazon.com/fis/home?#ExperimentTemplates), select the `FisWorkshopExp1` template we just created.  Under **"Actions"** select **"Start experiment"**.

{{< img "start-experiment-1.en.png" "Start experiment add tags" >}}

Let's give the experiment run a friendly name. It will make it easier to find it from the list page. Under "Experiment tags" enter `Name` for "Key and `FisWorkshopExp1Run1` then select **"Start experiment"**.

{{< img "start-experiment-2.en.png" "Start experiment confirmation" >}}

Because you are about to start a potentially destructive process, you will be asked to confirm that you really want to do this. Type `start` as directed and select **"Start experiment"**.

{{< img "start-experiment-3.en.png" "Start experiment" >}}

### Review results

Navigate to the [**FIS console**](https://console.aws.amazon.com/fis/home?#Experiments), select "Experiments", and click the experiment ID for the experiment you just started.

Look at the "State" entry. If this still shows pending, feel free to select the **"Refresh"** button a few times until you see a result. If you followed the above steps carefully there is a good chance that your experiment state will be `Failed`.

{{< img "run-experiment-1-fail.en.png" "Start experiment confirmation" >}}

Click on the failed result to get more information about why it failed. The message should say `Target resolution returned empty set`. Scroll down further and select "Timeline":

{{< img "run-experiment-1-fail-2.en.png" "Start experiment confirmation" >}}

In this case this doesn't show anything because the experiment failed to run entirely, but for larger experiments you would see when each action was active in the timeline.

Next navigate to the [**CloudWatch Logs console**](https://console.aws.amazon.com/cloudwatch/home?#logsV2:log-groups/log-group/$252Ffis-workshop$252Ffis-logs) and select the `/fis-workshop/fis-logs` log group

{{< img "run-experiment-1-fail-3.en.png" "Start experiment confirmation" >}}

then expand the topmost stream under "Log streams"

{{< img "run-experiment-1-fail-4.en.png" "Start experiment confirmation" >}}

All this shows that FIS failed to identify virtual machines that satisfied the condition of being "50% of instances with "Name" tag of `FisStackAsg/ASG`.

To see why this would happen, have a look at the auto scaling group from which we tried to select instances. Navigate to the [**EC2 console**](https://console.aws.amazon.com/ec2autoscaling/home?#/details), select **"Auto Scaling Groups"** on the bottom of the burger menu, and search for `FisStackAsg-`:

{{< img "review-1-asg-1.en.png" "Review ASG" >}}

## Learning and improving

It looks like our ASG was configured to scale down to just one instance while idle. Since we can't shut down half of one instance, our 50% selector came up empty and the experiment failed.

**Great! While this wasn't really what we expected, we just found a flaw in our configuration that would severely affect our system's resilience! Let's fix it and try again!**

Click on the Auto Scaling group name and **"Edit"** the "Group Details" to raise both the "Desired capacity" and "Minimum capacity" to `2`.

{{< img "review-1-asg-2.en.png" "Update ASG" >}}

Check the ASG details or the CloudWatch Dashboard we explored in the previous section to make sure the active instances count has come up to 2.

To repeat the experiment, repeat the steps above:

* restart the load
* navigate back to the [**FIS Experiment Templates Console**](https://console.aws.amazon.com/fis/home?#ExperimentTemplates), start the experiment adding a `Name` tag of `FisWorkshopExp1Run2`
* check to make sure the experiment succeeded

Finally navigate to the [**CloudWatch Dashboard**](https://console.aws.amazon.com/cloudwatch/home?#dashboards:) from the previous section. Review the number of instances in the ASG going down and then up again and review the error responses reported by the load test.

{{< img "cwdashboard-asg-1.en.png" "Number of Instances in ASG" >}}

## Findings and next steps

From this experiment we learned:

* Carefully choose the resource to affect and how to select them. If we had originally chosen to terminate a single instance (`COUNT`) rather than a fraction (`PERCENT`), we would have severely affected our service.
* Spinning up instances takes time. To achieve resilience, Auto Scaling groups should be set to have at least two instances running at all times

From here you can explore how to set up experiments programatically using the 
[**AWS CLI**]({{< ref "030_basic_content/030_basic_experiment/30-experiment-cli" >}}) or [**AWS CloudFormation**]({{< ref "030_basic_content/030_basic_experiment/40-experiment-cfn" >}}), or move on exploring [**more fault types**]({{< ref "030_basic_content/040_ssm" >}}) to inject.

