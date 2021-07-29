+++
title = "Review the Pipeline"
date =  2021-04-14T17:25:37-06:00
weight = 20
+++

Lets review the components our previous section created. 

## Code Commit

Open the [AWS Code Commit Console](https://console.aws.amazon.com/codesuite/codecommit/home?#Home).
You should see the newly created ```FIS_Workshop``` repository.

{{< img "codecommit.png" "Newly created AWS Code Commit repository" >}}

## Code Build

Open the [AWS Code Build Console](https://console.aws.amazon.com/codesuite/codebuild/projects). You should see the ```FIS_Workshop``` build project.

{{< img "codebuild.png" "AWS Code Build build project" >}}

## Code Pipeline

Open the [AWS Code Pipeline Console](https://console.aws.amazon.com/codesuite/codepipeline/home?#Home).
You should now see the ```FIS_Workshop``` pipeline.

{{< img "codepipeline.png" "AWS CodePipeline pipeline" >}}

{{% notice note %}} The pipeline will start in a failed state, since we have not uploaded any files to our repository. {{% /notice %}}

Click on the pipeline name, to review. 

This pipeline has 3 stages. 
1) **Source**: This stage will trigger the pipeline when a commit occurs in our repository.
1) **Infrastructure_Provisioning**: This stage will create our test infrastructure and create our experiment templates.
1) **FIS**: This stage will use the code build project to run our experiment and monitor the results. 

{{< img "codepipelinedetails1.png" "AWS CodePipeline source stage" >}}

{{< img "codepipelinedetails2.png" "AWS CodePipeline infrastructure provisioning and FIS experiment stages" >}}

Continue to the next section to start the pipeline.
