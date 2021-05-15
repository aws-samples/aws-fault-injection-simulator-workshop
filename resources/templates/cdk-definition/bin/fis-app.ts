#!/usr/bin/env node
import * as cdk from '@aws-cdk/core';
import { FisStackVpc } from '../lib/fis-stack-vpc';
import { FisStackAsg, FisStackAsgProps } from '../lib/fis-stack-asg';

const app = new cdk.App();

const fisVpc = new FisStackVpc(app, 'FisStackVpc');
const fisAsg = new FisStackAsg(app, 'FisAsgStack', { vpc: fisVpc.vpc});
