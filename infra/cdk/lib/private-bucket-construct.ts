import * as cdk from 'aws-cdk-lib';
import { BlockPublicAccess, Bucket, ObjectOwnership } from 'aws-cdk-lib/aws-s3';
import { Construct } from 'constructs';

type PrivateBucketConstructProps = {
    versioned?: boolean
    autoDeleteObjects: boolean
    removalPolicy: cdk.RemovalPolicy,
    bucketName: string
};

export class PrivateBucketConstruct extends Construct {
    public readonly bucket: Bucket;
    constructor(scope: Construct, id: string, props: PrivateBucketConstructProps) {
        super(scope, id);
        this.bucket = new Bucket(this, 'PrivateBucket', {
            blockPublicAccess: BlockPublicAccess.BLOCK_ALL,
            versioned: props.versioned,
            autoDeleteObjects: props.autoDeleteObjects,
            removalPolicy: props.removalPolicy,
            bucketName: props.bucketName,
            objectOwnership: ObjectOwnership.BUCKET_OWNER_ENFORCED
        });
    }
}