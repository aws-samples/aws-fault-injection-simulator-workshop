+++
title = "Experiment (Console)"
weight = 20
+++

In this section, we will learn over how to create an AWS FIS experiment template using the AWS Console. 

## Experiment setup

### Create an AWS FIS experiment template

To create a fault injection experiment, we first need to create an AWS FIS template defining the [Actions](https://docs.aws.amazon.com/fis/latest/userguide/actions.html), [Targets](https://docs.aws.amazon.com/fis/latest/userguide/targets.html), and optionally (but strongly recommended) the [Stop Conditions](https://docs.aws.amazon.com/fis/latest/userguide/stop-conditions.html).  

Navigate to the [FIS console](https://console.aws.amazon.com/fis/home?#Home) and select "Create experiment template".

{{< img "create-template-1.en.png" "AWS FIS console" >}}

{{% notice note %}}
**_Note:_** if you've used AWS FIS before you may not see the splash screen. In that case select "Experiment templates" in the menu on the left and access "Create experiment template" from there.
{{% /notice %}}

#### Template description and permissions

First, let's give a description of our experiment and an IAM role for the experiment. Go to the "Description and permission" section at the top. For "Description" enter `Terminate half of the instances in the auto scaling group` and for "Role" select the `FisWorkshopServiceRole` role you created above.

{{< img "create-template-2-description.en.png" "Set FIS description and role" >}}

#### Action definition

We first need to select which action to take. To test the hypothesis that we can safely impact half the instances in our Auto Scaling Group, we will terminate half of those instances. Go to the "Actions" section" and select "Add Action"

{{< img "create-template-2-actions-1.en.png" "Add FIS actions" >}}

For "Name" enter `FisWorkshopAsg-TerminateInstances` and add a "Description" like `Terminate instances`. For "Action type" select `aws:ec2:terminate-instances`.

We will leave the "Start after" section blank since the instances we are terminating are part of an Auto Scaling Group and we can let it create new instances to replace the terminated ones.

Leace the default "Target" `Instances-Target-1` and click "Save".

{{< img "create-template-2-actions-2.en.png" "Edit FIS actions" >}} #TO-UPDATE 

#### Target selection

Now, let's define the EC2 instances to terminate. For this first experiment, we want to prove the following hypothesis:  Since we use Auto Scaling, we can safely impact half the instances in our Auto Scaling Group. 
Scroll to the predefined "Instances-Target-1" section and click "Edit".

{{< img "create-template-2-targets-1.en.png" "Add FIS target" >}} #TO-UPDATE

Leave the default name and make sure the Resource type is `aws:ec2:instances`. For "Target method" we will dynamically select resources based on an associated tag. Select the `Resource tags and filters` checkbox. Pick `Percent` from "Selection mode" and enter `50`. Under "Resource tags" enter `Name` in the "Key" field and `FisStackAsg/ASG` for "Value". Under filters enter `State.Name` in the "Attribute path" field and `running` under "Values". We wil cover filters in more detail in the next section. Select "Save".

{{< img "create-template-2-targets-2.en.png" "Edit FIS target" >}} #TO-UPDATE


#### Creating template without stop conditions

Scroll to the bottom of the template definition page and select "Create experiment template". 

{{< img "create-template-3-create.en.png" "Create experiment template" >}} #TO-UPDATE


#### Template name

Finally, let's give our template a short name to be used on the list page. To do this scroll to the "Tags" section at the bottom, select "Add new tag", then enter `Name` in the "Key" field and `FisWorkshopExp1` for "Value"

{{< img "create-template-2-name.en.png" "Set FIS template name" >}} #TO-UPDATE

Since we didn't specify a stop condition we receive a warning. This is ok, for this experiment we won't use a stop condition. Type `create` in the text box as indicated and select "Create experiment template".

{{< img "create-template-3-confirm.en.png" "Confirm and save FIS template" >}} #TO-UPDATE

## Validation procedure

We will be using the CloudWatch dashboard from the previous sections for validation, no additional setup required.

## Run FIS experiment

As previously discussed, we should collect both customer and ops metrics. In future sections, we will show you how you can add the load generator into your experiments.

However, for this experiment we will manually generate load on the system before starting the experiment, similarly to what we did in the previous section. Here we have increased the run time to 5 minutes by setting `ExperimentDurationSeconds` to 300:

```bash
# Please ensure that LAMBDA_ARN and URL_HOME are still set from previous section
aws lambda invoke \
  --function-name ${LAMBDA_ARN} \
  --payload "{
        \"ConnectionTargetUrl\": \"${URL_HOME}\",
        \"ExperimentDurationSeconds\": 300,
        \"ConnectionsPerSecond\": 1000,
        \"ReportingMilliseconds\": 1000,
        \"ConnectionTimeoutMilliseconds\": 2000,
        \"TlsTimeoutMilliseconds\": 2000,
        \"TotalTimeoutMilliseconds\": 2000
    }" \
  --invocation-type Event \
  invoke.txt
```

{{% notice warning %}}
If you are running AWS CLI v2, you need to pass the parameter `--cli-binary-format raw-in-base64-out` or you'll get the error "Invalid base64" when sending the payload.
{{% /notice %}}

To start the experiment navigate to the [FIS console](https://console.aws.amazon.com/fis/home?#ExperimentTemplates), select the `FisWorkshopExp1` template we just created.  Under "Actions" select "Start experiment".

{{< img "start-experiment-1.en.png" "Start experiment add tags" >}}

Let's give the experiment run a friendly name. It will make it easier to find it from the list page. Under "Experiment tags" enter `Name` for "Key and `FisWorkshopExp1Run1` then select "Start experiment".

{{< img "start-experiment-2.en.png" "Start experiment confirmation" >}}

Because you are about to start a potentially destructive process, you will be asked to confirm that you really want to do this. Type `start` as directed and select "Start experiment".

{{< img "start-experiment-3.en.png" "Start experiment" >}}

### Review results

Navigate to the [FIS console](https://console.aws.amazon.com/fis/home?#Experiments), select "Experiments", and select the experiment ID for the experiment you just started.

Look at the "State" entry. If this still shows pending, feel free to select the "Refresh" button a few times until you see a result. If you followed the above steps carefully there is a good chance that your experiment state will be "Failed".

{{< img "run-experiment-1-fail.en.png" "Start experiment confirmation" >}}

Click on the failed result to get more information about why it failed. The message should say "Target resolution returned empty set". To see why this would happen, have a look at the auto scaling group from which we tried to select instances. Navigate to the [EC2 console](https://console.aws.amazon.com/ec2autoscaling/home?#/details), select "Auto Scaling Groups" on the bottom of the left menu, and search for "FisStackAsg-":

{{< img "review-1-asg-1.en.png" "Review ASG" >}}

## Learning and improving

It looks like our ASG was configured to scale down to just one instance while idle. Since we can't shut down half of one instance our 50% selector came up empty and the experiment failed.

**Great! While this wasn't really what we expected, we just found a flaw in our configuration that would severely affect our system's resilience! Let's fix it and try again!**

Click on the auto scaling group name and "Edit" the "Group Details" to raise both the "Desired capacity" and "Minimum capacity" to `2`.

{{< img "review-1-asg-2.en.png" "Update ASG" >}}

Check the ASG details or the CloudWatch Dashboard we explored in the previous section to make sure the active instances count has come up to 2.

To repeat the experiment, repeat the steps above:

* restart the load
* navigate back to the [FIS Experiment Templates Console](https://console.aws.amazon.com/fis/home?#ExperimentTemplates), start the experiment adding a `Name` tag of `FisWorkshopExp1Run2`
* check to make sure the experiment succeeded

Finally navigate to the [CloudWatch Dashboard](https://console.aws.amazon.com/cloudwatch/home?#dashboards:) from the previous section. Review the number of instances in the ASG going down and then up again and review the error responses reported by the load test.

{{< img "cwdashboard-asg-1.en.png" "Number of Instances in ASG" >}}

## Findings and next steps

From this experiment we learned:

* Carefully choose the resource to affect and how to select them. If we had originally chosen to terminate a single instance (COUNT) rather than a fraction (PERCENT), we would have severely affected our service.
* Spinning up instances takes time. To achieve resilience, Auto Scaling groups should be set to have at least two instances running at all times

In the next section we will explore larger experiments.
