+++
title = "Start the Pipeline"
weight = 30
+++

The pipeline is configured to run every time new code is committed to our AWS CodeCommit repository. To start our pipeline we need to commit files to our repository.  

## Update repository

{{% notice note %}}
The instructions below are designed for use with Cloud9. On Cloud9 git access is enabled via the IAM role associated with the Cloud9 instance. If you would like to access the AWS CodeCommit repository from your local machine, review the [**getting started documentation**](https://docs.aws.amazon.com/codecommit/latest/userguide/getting-started.html).
{{% /notice %}}

Adding files to our repository is a 3-step process:

* create a local copy of our repository (`clone`)
* add or update files and save them (`add` / `commit`)
* upload them to our repo (`push`)

### Clone

Open the [AWS Code Commit Console](https://console.aws.amazon.com/codesuite/codecommit/home?#Home). Click the `HTTPS` link next to the `FIS_Workshop` repository name to copy the URL to the clipboard. 

In your Cloud9 terminal clone the repository (replace the URL in the example by pasting from the clipboard):

```bash
GIT_URL=$( aws codecommit get-repository --repository-name FIS_Workshop --query "repositoryMetadata.cloneUrlHttp" --output text )
cd ~/environment
git clone ${GIT_URL}
cd FIS_Workshop
```

### Add/Update

Copy the sample files from the resources section into the newly cloned repository.

```bash
cp ~/environment/aws-fault-injection-simulator-workshop/resources/code/cdk/cicd/resources/* ~/environment/FIS_Workshop/
```
 
Since this is the first time working with code commit, we should setup our username and email for the commit history.
Run the below commands, be sure to replace the details with your information.

```bash
git config --global user.name "Your Name"
git config --global user.email you@example.com
```

Finally `add` all the files in the directory, and `commit` them as a new version with a label of `Uploading Workshop files`.
 
```bash
git add .
git commit -am "Uploading Workshop files"
```

### Push

Finally `push` the files to copy them to our repository and to trigger the pipeline:

```bash
git push -u
```

## View Progress

After you `push` the files, the pipeline will start. 
Open the [**AWS CodePipeline Console**](https://console.aws.amazon.com/codesuite/codepipeline/home?#Home).
You should now see the `FIS_Workshop` pipeline is in progress.
Click on the pipeline name to view the step details.

{{< img "codepipelineinprogress.png" "AWS CodePipeline in progress" >}}

The pipeline runs in sequence, first running the Wait for the "Infrastructure_Provisioning" step, and on success starting the "FIS" step. 

You can monitor the progress of our experiment either from the CodePipeline details page or from the AWS FIS console. 

Navigate to the [**FIS console**](https://console.aws.amazon.com/fis/home?#Experiments). Click on the "Experiment ID" of the running experiment.
You should see the experiment in a running status: 

{{< img "fisrunning.png" "Running Experiment" >}}

If you expand the "instanceActions / aws:ec2:stop-instance" card (as shown above) you can see that the experiment stops the test instance, waits for 1minute, then restarts the instance. 

Wait a couple minutes for the instance to restart and the experiment to finish and refresh the page. You should see the experiment is completed successfully.

{{< img "fissuccessfully.png" "Successful Experiment" >}}

Finally navigate back to the [**AWS CodePipeline Console**](https://console.aws.amazon.com/codesuite/codepipeline/home?#Home).
You should also see that your pipeline has completed successfully.

{{< img "codepipelinesuccessfully.png" "Successful Pipeline" >}}

Congratulations! You have successfully integrated a Fault Injection Simulator Experiment into a CI/CD pipeline.
In this scenario, we completed a happy path to ensure that our infrastructure and experiment completed without error. 
Continue on to the next section, where we will deploy a new version of our CloudFormation template and force our experiment (and pipeline) to fail. 
