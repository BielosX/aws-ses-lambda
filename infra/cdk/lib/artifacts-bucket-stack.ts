import * as cdk from 'aws-cdk-lib';
import { BlockPublicAccess, Bucket, ObjectOwnership } from 'aws-cdk-lib/aws-s3';
import { Construct } from 'constructs';

export class ArtifactsBucketStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);
    var bucket = new Bucket(this, 'ArtifactsBucket', {
      blockPublicAccess: BlockPublicAccess.BLOCK_ALL,
      versioned: true,
      autoDeleteObjects: true,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
      bucketName: `artifacts-bucket-${this.region}-${this.account}`,
      objectOwnership: ObjectOwnership.BUCKET_OWNER_ENFORCED
    });
    new cdk.CfnOutput(this, 'ArtifactsBucketName', {
      value: bucket.bucketName,
      exportName: 'artifacts-bucket-name'
    });
  }
}
