#!/usr/bin/env node
import * as cdk from '@aws-cdk/core';
import { CdkDefinitionStack } from '../lib/cdk-definition-stack';

const app = new cdk.App();
new CdkDefinitionStack(app, 'CdkDefinitionStack');
