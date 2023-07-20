import * as cdk from 'aws-cdk-lib';
import { Bucket } from 'aws-cdk-lib/aws-s3';
import { Construct } from 'constructs';
import { SesConstruct } from './ses-construct';
import { LambdaConstruct } from './lambda-construct';

export class LambdaAppStack extends cdk.Stack {
    constructor(scope: Construct, id: string, props?: cdk.StackProps) {
        super(scope, id, props);
        const domain = this.node.tryGetContext('domain');
        const sandboxToEmail = this.node.tryGetContext('sandboxToEmail');
        const artifactName = this.node.tryGetContext('artifactName');
        const bucketName = cdk.Fn.importValue('artifacts-bucket-name');
        const artifactBucket = Bucket.fromBucketName(this, 'ArtifactsBcuket', bucketName);
        const ses = new SesConstruct(this, 'Ses', {
            domain,
            sandboxToEmail,
            emailBucketName: `email-bucket-${this.region}-${this.account}`
        });
        new LambdaConstruct(this, 'Lambda', {
            emailReceivedTopic: ses.helpEmailReceivedTopic,
            fromDomain: domain,
            artifactName,
            artifactBucket
        });
    }
}