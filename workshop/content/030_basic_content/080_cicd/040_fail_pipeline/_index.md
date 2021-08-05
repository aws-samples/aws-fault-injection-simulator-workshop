+++
title = "Force a Pipeline Error"
weight = 40
+++

In this section we will update our repository to deploy a new version of our experiment and infrastructure.
Then while our pipeline is running, we will force an error to test that our pipeline will stop on a failed experiment. 

## Change the Infrastructure Template

We will be making a change to our CloudFormation template that creates our EC2 Instance and defines our experiment. 
Open the [AWS Code Commit Console](https://console.aws.amazon.com/codesuite/codecommit/home?#Home) and select the ```FIS_Workshop``` repository.
Click on ```cfn_fis_demos.yaml``` and select edit in the upper right hand corner.
Edit the file to comment out line ```122``` and uncomment lines ```123``` -> ```127```.

Before:
{{< img "sourcebefore.png" "Source Before" >}}

After:
{{< img "sourceafter.png" "Source After" >}}

Finally, enter your name and email at the bottom of the page and commit the change.
This will trigger the pipeline to start immediately. 

## Forcing an Error

To simulate an failed experiment, we will manually set our CloudWatch alarm to an error state.
Navigate back to the [AWS Code Pipeline Console](https://console.aws.amazon.com/codesuite/codepipeline/home?#Home) and watch the pipeline status. 
Once the FIS section changes to in progress, run the below command from your workstation to force an error. 

```
aws cloudwatch set-alarm-state --alarm-name "NetworkInAbnormal" --state-value "ALARM" --state-reason "testing FIS"
```

By setting this CloudWatch alarm to an error state, this will stop the experiment.
Open the [FIS console](https://console.aws.amazon.com/fis/home?#Experiments).
You should see that your latest experiment has failed do to the stop condition. 

{{< img "fisfail.png" "Failed Experiment" >}}

Finally navigate back to the [AWS Code Pipeline Console](https://console.aws.amazon.com/codesuite/codepipeline/home?#Home).
You should see that your pipeline has also failed do to the experiment stopping.

{{< img "codepipelinefail.png" "Failed Pipeline" >}}

Congratulations! We have now tested that a failure to our experiment will stop our pipeline.
In a production scenario, after the experiment step, we would continue on with our deployment to the next stage in our pipeline. 
More mature deployments could also leverage various experiments each with more disruptive behavior against different environments until our application makes it to production.
