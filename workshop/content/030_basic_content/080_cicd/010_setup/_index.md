+++
title = "Setup"
weight = 10
+++

In this section, we will integrate a Fault Injection Simulator experiment with a CICD pipeline.

## Create The Pipeline

We will use the AWS CDK to provision our CICD pipeline.
First start by cloning the repository for the workshop.

```
cd ~/environment
git clone https://github.com:aws-samples/aws-fault-injection-simulator-workshop.git
```

Next change directory into the CICD CDK project and restore the npm packages used for the pipeline.

```
cd aws-fault-injection-simulator-workshop/resources/code/cdk/cicd/
npm install
```

Finally lets deploy our stack.

```
cdk deploy --require-approval never
```

The stack will take a few minutes to complete. 
You can monitor the progress from the CloudFormation Console. 
Continue to the next section.
