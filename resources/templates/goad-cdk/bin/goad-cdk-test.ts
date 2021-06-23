#!/usr/bin/env node
import 'source-map-support/register';
import * as cdk from '@aws-cdk/core';
import { GoadCdkTestStack } from '../lib/goad-cdk-test-stack';

const app = new cdk.App();
new GoadCdkTestStack(app, 'FisStackLoadGen', {
  env: { 
    account: process.env.CDK_DEFAULT_ACCOUNT, 
    region: process.env.CDK_DEFAULT_REGION 
}});
