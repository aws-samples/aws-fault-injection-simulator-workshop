+++
title = "Start the Pipeline"
date =  2021-04-14T17:25:37-06:00
weight = 30
+++

To start our pipeline we need to commit files to our CodeCommit repository. 
The commit action will trigger the pipeline that provisions our infrastructure and then runs our experiment. 

## Commit Files

Start by cloning the ```FIS_Workshop``` repository.
Open the [AWS Code Commit Console](https://console.aws.amazon.com/codesuite/codecommit/home?#Home). 
Click the HTTPS link next to the repository name. 
See the below command for an example, when working in the ```US-EAST-1``` region.

```
cd ~/environment
git clone https://git-codecommit.us-east-1.amazonaws.com/v1/repos/FIS_Workshop
cd FIS_Workshop
```

Copy the sample files from the resources section into the newly cloned repository.

```
cp ~/environment/aws-fault-injection-simulator-workshop/resources/code/cdk/cicd/resources/* ~/environment/FIS_Workshop/
```
 
Since this is the first time working with code commit, we should setup our username and email for the commit history.
Run the below commands, be sure to replace the details with your information.

```
git config --global user.name "Your Name"
git config --global user.email you@example.com
```

Finally commit the files to start the pipeline.

```
git add .
git commit -am "Uploading Workshop files"
git push -u
```

## View Progress

After you commit the files, the pipeline will start. 
Open the [AWS Code Pipeline Console](https://console.aws.amazon.com/codesuite/codepipeline/home?#Home).
You should now see the ```FIS_Workshop``` pipeline is in progress.
Click on the pipeline name to view the step details.

![CodePipeline in Progress](codepipelineinprogress.png)

Wait for the infrastructure provisioning step to complete. 
After this step, our Experiment will start.
You can monitor the progress of your experiment from both the CodePipeline details page of the [FIS console](https://console.aws.amazon.com/fis/home?#Experiments). 

Click on the running experiment.
You should see the experiment in a running status. 

![Running Experiment](fisrunning.png)

After a few minutes refresh the page. 
You should see the experiment is completed successfully.

![Successful Experiment](fissuccessfully.png)

Finally navigate back to the [AWS Code Pipeline Console](https://console.aws.amazon.com/codesuite/codepipeline/home?#Home).
You should also see that your pipeline has completed successfully.

![Successful Pipeline](codepipelinesuccessfully.png)

Congratulations! You have successfully integrated a Fault Injection Simulator Experiment into a CICD pipeline.
In this scenario, we completed a happy path to ensure that our infrastructure and experiment completed without error. 
Continue on to the next section, where we will deploy a new version of our CloudFormation template and force our experiment (and pipeline) fail. 