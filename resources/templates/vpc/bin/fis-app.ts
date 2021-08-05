#!/usr/bin/env node
import * as cdk from '@aws-cdk/core';
import { FisStackVpc } from '../lib/fis-stack-vpc';
// import { FisStackAsg, FisStackAsgProps } from '../lib/fis-stack-asg';

const app = new cdk.App();

const fisVpc = new FisStackVpc(app, 'FisStackVpc', { 
    env: { 
        account: process.env.CDK_DEFAULT_ACCOUNT, 
        region: process.env.CDK_DEFAULT_REGION 
    },    
    description: "AWS FIS workshop - VPC stack. Creates VPC referenced by all other workshop resources"
});
// const fisAsg = new FisStackAsg(app, 'FisAsgStack', { vpc: fisVpc.vpc});
