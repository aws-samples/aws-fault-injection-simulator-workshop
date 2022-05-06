---
title: "Setup"
weight: 10
services: true
---

In this section, we will integrate an AWS Fault Injection Simulator experiment with a CI/CD pipeline.

## Create The Pipeline

We will use the AWS CDK to provision our CI/CD pipeline.  

If you have not done so yet, in your Cloud9 terminal clone the repository for the workshop.

```bash
mkdir -p ~/environment
cd ~/environment
git clone https://github.com/aws-samples/aws-fault-injection-simulator-workshop.git
```

Next change directory into the CI/CD CDK project and restore the npm packages used for the pipeline.

```bash
cd ~/environment/aws-fault-injection-simulator-workshop/resources/code/cdk/cicd/

# Make sure we use right npm version
sudo npm install -g npm@7

# Pull relevant npm packages
npm install
```

Finally lets deploy our stack.

```bash
# use local version of cdk
npx cdk deploy --require-approval never
```

The stack will take a few minutes to complete. You can monitor the progress from the CloudFormation Console. 

Once stack creation is complete, continue to the next section.
