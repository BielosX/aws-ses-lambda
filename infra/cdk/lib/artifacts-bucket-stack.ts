import * as cdk from 'aws-cdk-lib';
import {Construct} from 'constructs';
import {PrivateBucketConstruct} from "./private-bucket-construct";

export class ArtifactsBucketStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);
    const bucket = new PrivateBucketConstruct(this, 'ArtifactsBucket', {
      versioned: true,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
      autoDeleteObjects: true,
      bucketName: `artifacts-bucket-${this.region}-${this.account}`
    });
    new cdk.CfnOutput(this, 'ArtifactsBucketName', {
      value: bucket.bucket.bucketName,
      exportName: 'artifacts-bucket-name'
    });
  }
}
