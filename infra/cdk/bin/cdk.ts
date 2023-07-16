#!/usr/bin/env node
import 'source-map-support/register';
import * as cdk from 'aws-cdk-lib';
import { ArtifactsBucketStack } from '../lib/artifacts-bucket-stack';

const app = new cdk.App();

new ArtifactsBucketStack(app, 'ArtifactsBucketStack');

app.synth();