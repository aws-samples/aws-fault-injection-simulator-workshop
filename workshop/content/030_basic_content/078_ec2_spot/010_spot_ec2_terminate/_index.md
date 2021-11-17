---
title: "Baselining"
chapter: false
weight: 10
services: true
---


## Experiment idea

In this section we explore the effect of regular EC2 instance termination on an experiment with checkpoints enabled:

* **Given**: we have am AWS Step Functions workflow that will restart spot instances until the job is 100% finished.
* **Hypothesis**: terminating an EC2 spot instance will require additional computation but the job will reach 100% completion without human intervention.

## Experiment setup

{{% notice note %}}
We are assuming that you know how to set up a basic FIS experiment and will focus on things specific to this experiment. If you need a refresher see the previous [**First Experiment**]({{< ref "030_basic_content/030_basic_experiment/" >}}) section.
{{% /notice %}}

### General template setup

* Create a new experiment template
  * Add "Name" tag of `FisWorkshopSpotTerminate`
  * Add "Description" of `Use EC2 terminate instances on spot instance`
  * Select `FisWorkshopSpotRole` as execution role

#### Action / Target definition 1

In this experiment we will introduce an initial wait before triggering instance termination. Go to the “Actions” section and select **“Add Action”**.

For "Name" enter `AllowSomeCompletion` and add a "Description" like `Wait for some compute to happen before termination`. For "Action type" select `aws:fis:wait` and for "Action parameters" / "duration" select `3` minutes. Select **“Save”**.

{{<img "wait-action.png" "Wait action definition" >}}

#### Action / Target definition 2

Following the same process as described in [**First Experiment**]({{<ref "030_basic_content/030_basic_experiment/20-experiment-console">}}) define actions:

* "Name": `FisWorkshopSpot-TerminateInstance`
* "Description": `Use terminate instances on spot instances`
* "Action Type": `aws:ec2:terminate-instances`

Since we want this action to execute after an initial wait, select the `AllowSomeCompletion` action from the "Start after" drop down.

{{<img "terminate-action.png" "Terminate action definition" >}}

Define targets by editing the auto-generated `Instances-Target-1` using:

* "Name": `FisWorkshopSpot-SpotInstance`
* "Resource type": `aws:ec2:instance`
* "Target method": "Resource tags and filters
* "Selection mode": "All"
* "Resource tags": 
  * "Key": `Name`
  * "Value": `Fis/Spot`
* "Resource filters":
  * "Attribute path": `State.Name`
  * "Values": `running`

## Validation procedure  

Similar to the first experiment we will use a CloudWatch dashboard created as part of resource creation. Navigate to the [**CloudWatch console**](https://console.aws.amazon.com/cloudwatch/home?#dashboards:) and select a dashboard named "FisSpot-REGION", e.g. `FisSpot-us-west-2`. 

## Run FIS experiment

First we need to start the StepFunctions workflow. For demonstration purposes we will run this with a total duration of 6 minutes and a checkpoint duration of 2 minutes but if you have the time you may want to explore what happens if you set checkpoint duration to >= total duration.

```
STATE_MACHINE_ARN=$( aws stepfunctions list-state-machines --query "stateMachines[?contains(name,'SpotChaosStateMachine')].stateMachineArn" --output text )

aws stepfunctions start-execution \
  --state-machine-arn ${STATE_MACHINE_ARN} \
  --input '{ "JobDuration": "6", "CheckpointDuration": "2"}'
```

{{% notice warning %}}
Currently all target resolution is performed at the beginning of the experiment run. As such it is possible that the FIS experiment will fail target resolution if the spot instance is not running yet. If that happens 
{{% /notice %}}

Then start the experiment. If you named the template as described above this should work, otherwise adjust `EXPERIMENT_TEMPLATE_ID` as needed:

```
EXPERIMENT_TEMPLATE_ID=$( aws fis list-experiment-templates --query "experimentTemplates[?tags.Name=='FisWorkshopSpotTerminate'].id" --output text )

aws fis start-experiment \
  --experiment-template-id $EXPERIMENT_TEMPLATE_ID \
  --tags Name=FisWorkshopSpotTerminateTest \
| jq -rc '.experiment.id'
```

Copy the experiment ID and navigate to the [**FIS console**](https://console.aws.amazon.com/fis/home?#Experiments). Search for the experiment ID and check that the state is "running". If the experiment failed because of empty target lookup, run the start experiment command again.

If the experiment keeps failing, navigate to the [**StepFunctions console**](https://console.aws.amazon.com/states/home?#/statemachines), select the "SpotChaosStateMachine" and examine the most recent execution to ensure a spot instance has been created.

Finally navigate to the [**CloudWatch console**](https://console.aws.amazon.com/cloudwatch/home?#dashboards:), select the FisSpot dashboard and set a custom duration of 15min:

{{<img "dashboard-custom-duration.png" "Set custom viewport duration">}}

You may have to wait for a few minutes for data to become available. You should then see data like this (no checkpoint happened before interruption):

{{<img "terminate-no-checkpoint.png" "Spot instance terminated before checkpoint">}}

## Learning and improving

From the graphs we can see that the workflow will successfully restart from the last checkpoint. However, we can also see that a substantial amount of progress has to be re-calculated and it would be better if we could save progress closer to the actual interruption of the instance. In the next section we will repeat the same experiment but using the `aws:ec2:send-spot-instance-interruptions` action which will replicate normal spot instance interruption behavior by sending a notification before terminating the instance.

