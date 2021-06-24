#!/usr/bin/env node
import 'source-map-support/register';
import * as cdk from '@aws-cdk/core';
import { FisStackRdsAurora } from '../lib/fis-stack-rds-aurora';

const app = new cdk.App();
const fisRds = new FisStackRdsAurora(app, 'FisStackRdsAurora', {
  env: { 
      account: process.env.CDK_DEFAULT_ACCOUNT, 
      region: process.env.CDK_DEFAULT_REGION 
  }});

