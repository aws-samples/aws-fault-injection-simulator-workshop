---
title: "Force a Pipeline Error"
weight: 40
services: true
---

In this section we will update the experiment template defined in our repository to contain a stop condition that will prevent or abort experiment execution if our cloudwatch alarm is in ALARM state. 

We will then `push` the new revision to our repository which will trigger a new pipeline run, update our experiment template and execute our experiment template. Then while our pipeline is running, we will force an ALARM state. This will lead to a failure of the AWS FIS experiment and in turn to a failure of the pipeline.

## Change the Infrastructure Template

{{% notice note %}}
In this section we are directly updating the file in AWS CodeCommit. This is equivalent to the `add` / `commit` / `push` process that we performed in the previous section and creates a new revision. To subsequently synchronize the copy on your Cloud9 instance you would `git pull`
{{% /notice %}}

We will be making a change to our CloudFormation template that creates our EC2 Instance and defines our experiment. 

Open the [**AWS CodeCommit Console**](https://console.aws.amazon.com/codesuite/codecommit/home?#Home) and select the `FIS_Workshop` repository. Click on `cfn_fis_demos.yaml` and select **"Edit"** in the upper right hand corner. Edit the file as shown below to enable am AWS CloudWatch alarm as a Stop Condition. 

Before:
{{< img "sourcebefore.en.png" "Source Before" >}}

After:
{{< img "sourceafter.en.png" "Source After" >}}

Finally, enter your name and email at the bottom of the page and select "Commit changes". Just like our prior `git push` this will trigger the pipeline to start. 

## Forcing an Error

To trigger the stop condition and simulate a failed experiment, we will manually set our CloudWatch alarm to an error state.

Navigate back to the [**AWS CodePipeline Console**](https://console.aws.amazon.com/codesuite/codepipeline/home?#Home) and watch the pipeline status. Once the FIS section changes to in progress, run the below command from your Cloud9 instance to force an error. 

```bash
aws cloudwatch set-alarm-state --alarm-name "NetworkInAbnormal" --state-value "ALARM" --state-reason "testing FIS"
```

By setting this CloudWatch alarm to an error state, this will stop a running experiment or prevent the experiment from starting.

{{% notice note %}}
We are artificially changing the alarm state. The alarm will reset to OK state after a short period of time. If you want to persist the ALARM state for longer try running the command in a loop.
{{% /notice %}}

To verify the Experiment was stopped, navigate to the [**FIS console**](https://console.aws.amazon.com/fis/home?#Experiments). You should see that your latest experiment has failed due to the stop condition. 

{{< img "fisfail.en.png" "Failed Experiment" >}}

To verify that this resulted in a failed pipeline execution navigate back to the [**AWS CodePipeline Console**](https://console.aws.amazon.com/codesuite/codepipeline/home?#Home). You should see that your pipeline has also failed do to the experiment stopping.

{{< img "codepipelinefail.en.png" "Failed Pipeline" >}}

Congratulations! You have built a CI/CD pipeline, instrumented it with an AWS FIS experiment, and demonstrated both successful and failed experiment outcomes.

## Next steps

From this starting point you can explore improvements like:

* **add more pipeline stages** - In our pipeline the experiment is the last step and does not gate progress. In a production scenario there might be a additional steps that would only run if the AWS FIS experiment succeeds. Try adding a pipeline stage and verify that it only runs if the experiment succeeds.
* **explore alternative ways to change the template** - in this example we are using an AWS CloudFormation template to define the experiment template as shown in the [**Experiment (CloudFormation)**]({{< ref "030_basic_content/030_basic_experiment/40-experiment-cfn" >}}) section. Could you store the experiment template as a separate file and update it using the CLI as show in [**Experiment (CLI)**]({{< ref "030_basic_content/030_basic_experiment/30-experiment-cli" >}}) or expand the `runExperiment.py` script (see [**code in GitHub**](https://github.com/aws-samples/aws-fault-injection-simulator-workshop/blob/main/resources/code/cdk/cicd/resources/runExperiment.py))?
* **trigger AWS CloudWatch alarm from experiment template** - AWS FIS templates allow you to run a sequence of steps, try triggering the alarm from a step in the template. Hint: you could do this via the [**AWS Sytems Manager integration**](){{< ref "030_basic_content/040_ssm" >}}.
* **set up a real alarm** 

