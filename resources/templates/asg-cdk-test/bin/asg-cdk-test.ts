#!/usr/bin/env node
import 'source-map-support/register';
import * as cdk from '@aws-cdk/core';
import { AsgCdkTestStack } from '../lib/asg-cdk-test-stack';

const app = new cdk.App();
new AsgCdkTestStack(app, 'AsgCdkTestStack', {
  env: { 
    account: process.env.CDK_DEFAULT_ACCOUNT, 
    region: process.env.CDK_DEFAULT_REGION 
}});
