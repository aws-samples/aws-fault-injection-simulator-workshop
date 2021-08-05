+++
title = "Cicd"
weight = 80
+++

In this section, we will discuss how to integrate a Fault Injection Simulator experiment with a CICD pipeline.

A natural progression for customers as they start to adopt chaos engineering, is to integrate experiments into their existing CICD pipelines.
Just like unit tests, integrations tests, and load tests, chaos experiments are a valuable tool to determining the robustness of a new piece of software.
By running an experiment as part of the pipeline, you can ensure that every new release meets your companies defined quality gates of reliability and performance.
Remember that chaos engineering should not be viewed as a replacement for other types of test, but an enhancement to your existing testing strategy. 

Fault Injection Simulator allows us to programmatically execute an experiment through an API.
We will use this API call as part of the pipeline to start the experiment on each checkin to our repository. 
Next a process will run and monitor the execution of the pipeline.
At this point, we can make a determination if the release (experiment passing) was successful and continue our deployment. 

In this next section, we will create a CICD pipeline using the AWS Code Suite of tools. 
From there we will use this pipeline to apply a CloudFormation Template on each checkin that provisions our sample infrastructure and as our Fault Injection Experiment. 
The last stage in out pipeline is to run the experiment against our infrastructure.
