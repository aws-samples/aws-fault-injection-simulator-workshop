+++
title = "Setup"
weight = 10
+++

In this section, we will integrate an AWS Fault Injection Simulator experiment with a CI/CD pipeline.

## Create The Pipeline

We will use the AWS CDK to provision our CI/CD pipeline.  

If you have not done so yet, in your cloud9 terminal clone the repository for the workshop.

```bash
cd ~/environment
git clone https://github.com/aws-samples/aws-fault-injection-simulator-workshop.git
```

Next change directory into the CI/CD CDK project and restore the npm packages used for the pipeline.

```bash
cd aws-fault-injection-simulator-workshop/resources/code/cdk/cicd/
npm install
```

Finally lets deploy our stack.

```bash
cdk deploy --require-approval never
```

The stack will take a few minutes to complete. You can monitor the progress from the CloudFormation Console. 

Once stack creation is complete, continue to the next section.
