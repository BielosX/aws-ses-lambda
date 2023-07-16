#!/usr/bin/env node
import * as cdk from 'aws-cdk-lib';
import { ArtifactsBucketStack } from '../lib/artifacts-bucket-stack';

const app = new cdk.App();

new ArtifactsBucketStack(app, 'ArtifactsBucketStack');

app.synth();