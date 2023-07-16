#!/usr/bin/env node
import * as cdk from 'aws-cdk-lib';
import { LambdaAppStack } from '../lib/lambda-app-stack';

const app = new cdk.App();

new LambdaAppStack(app, 'LambdaAppStack');

app.synth();