#!/usr/bin/env node
import * as cdk from 'aws-cdk-lib';
import { LambdaAppStack } from '../lib/lambda-app-stack';
import {ApiGatewayV2Stack} from "../lib/api-gateway-v2-stack";

const app = new cdk.App();

const lambdaAppStack = new LambdaAppStack(app, 'LambdaAppStack');
new ApiGatewayV2Stack(app, 'ApiGatewayStack', {
    welcomeLambdaAliasArn: lambdaAppStack.welcomeLambdaAliasArn
})

app.synth();