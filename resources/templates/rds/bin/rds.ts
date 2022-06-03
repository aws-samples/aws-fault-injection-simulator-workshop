#!/usr/bin/env node
import 'source-map-support/register';
import * as cdk from 'aws-cdk-lib';
import { FisStackRdsAurora } from '../lib/fis-stack-rds-aurora';

const app = new cdk.App();
const fisRds = new FisStackRdsAurora(app, 'FisStackRdsAurora', {
  env: { 
      account: process.env.CDK_DEFAULT_ACCOUNT, 
      region: process.env.CDK_DEFAULT_REGION 
    },
    description: "AWS FIS workshop - database stack. Creates RDS and Aurora resources for disruption"
  });

