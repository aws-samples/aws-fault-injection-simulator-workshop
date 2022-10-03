---
title: "Simulating interrupts"
chapter: false
weight: 20
services: true
---


## Experiment idea

In this section we explore how to mitigate the effect of instance interruption by reacting to the spot instance interrupt notification:

* **Given**: we have am AWS Step Functions workflow that will restart spot instances until the job is 100% finished.
* **Hypothesis**: capturing the spot instance interrupt request and checkpointing when it is received will better utilize EC2 spot instances and the job will still reach 100% completion without human intervention.

## Experiment setup

{{% notice note %}}
We will follow the exact same steps as in the [**previous section**]({{< ref "030_basic_content/078_ec2_spot/010_spot_ec2_terminate/" >}}). We will only change the action type from `aws:ec2:instance` to `aws:ec2:send-spot-instance-interruptions`.
{{% /notice %}}

{{% notice warning %}}
Even though the target selection looks the same as before, spot instance target selection is distinct from EC2 instance target selection. For this reason it is recommended that you create a completely new experiment template here instead of just editing the previous one.
{{% /notice %}}


### General template setup

* Create a new experiment template
  * Add "Name" tag of `FisWorkshopSpotInterrupt`
  * Add "Description" of `Use spot instance interruption on spot instance`
  * Select `FisWorkshopSpotRole` as execution role

#### Action / Target definition 1

Define action:

* "Name": `AllowSomeCompletion`
* "Description": `Wait for some compute to happen before termination`
* "Action Type": `aws:fis:wait`
* "Action parameters" / "duration": `3` minutes

{{<img "wait-action.en.png" "Wait action definition" >}}

#### Action / Target definition 2

Define action:

* "Name": `FisWorkshopSpot-InterruptInstance`
* "Description": `Use spot instance interruption on spot instances`
* "Action Type": `aws:ec2:send-spot-instance-interruptions`
* "Start after": `AllowSomeCompletion`

We also need to set an amount of time to pass between the notification and the actual instance termination. We will set this to the minimum allowed value of `2` minutes:

{{<img "terminate-action.en.png" "Terminate action definition" >}}

Define targets by editing the auto-generated `SpotInstances-Target-1` using:

* "Name": `FisWorkshopSpot-SpotInstance`
* "Resource type": `aws:ec2:spot-instance`
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
Currently all target resolution is performed at the beginning of the experiment run. As such it is possible that the FIS experiment will fail target resolution if the spot instance is not running yet. If that happens, wait a few seconds and restart the FIS experiment below.
{{% /notice %}}

Then start the experiment. If you named the template as described above this should work, otherwise adjust `SPOT_EXPERIMENT_TEMPLATE_ID` as needed:

```
SPOT_EXPERIMENT_TEMPLATE_ID=$( aws fis list-experiment-templates --query "experimentTemplates[?tags.Name=='FisWorkshopSpotInterrupt'].id" --output text )

aws fis start-experiment \
  --experiment-template-id $SPOT_EXPERIMENT_TEMPLATE_ID \
  --tags Name=FisWorkshopSpotInterruptTest \
| jq -rc '.experiment.id'
```

Copy the experiment ID and navigate to the [**FIS console**](https://console.aws.amazon.com/fis/home?#Experiments). Search for the experiment ID and check that the state is "running". If the experiment failed because of empty target lookup, run the start experiment command again.

If the experiment keeps failing, navigate to the [**StepFunctions console**](https://console.aws.amazon.com/states/home?#/statemachines), select the "SpotChaosStateMachine" and examine the most recent execution to ensure a spot instance has been created.

Finally navigate to the [**CloudWatch console**](https://console.aws.amazon.com/cloudwatch/home?#dashboards:), select the FisSpot dashboard and set a custom duration of 15min:

{{<img "dashboard-custom-duration.en.png" "Set custom viewport duration">}}

You may have to wait for a few minutes for data to become available. You should then see data like this. In this graph a checkpoint happened at the 2minute mark and another checkpoint immediately after that resulting from the instance interruption. Notably the newly created spot instance did not have to re-do any of the work:

{{<img "checkpoint-at-interrupt.en.png" "Checkpointing at interrupt">}}


## Learning and improving

Capturing the spot instance interruption notice and acting on it can substantially decrease the amount of repeated calculations. 

In our example the checkpointing is instantaneous whereas in the real world checkpointing might require substantial amounts of time for data offloading, writing to databases etc. With the ability to simulate interruption behavior you can now tune your interrupt behavior to make the most of your spot resources. 
