#!/usr/bin/env node
import 'source-map-support/register';
import * as cdk from 'aws-cdk-lib';
import { AsgCdkTestStack } from '../lib/asg-cdk-test-stack';

const app = new cdk.App();
new AsgCdkTestStack(app, 'FisStackAsg', {
  env: { 
    account: process.env.CDK_DEFAULT_ACCOUNT, 
    region: process.env.CDK_DEFAULT_REGION 
  },
  description: "AWS FIS workshop - EC2/autoscaling group stack. Creates an EC2 autoscaling group and associated CloudWatch dashboards for disruption"
});
