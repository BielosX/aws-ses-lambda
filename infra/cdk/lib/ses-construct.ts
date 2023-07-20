import {ServicePrincipal} from 'aws-cdk-lib/aws-iam';
import {EmailIdentity, Identity, ReceiptRuleSet} from 'aws-cdk-lib/aws-ses';
import {S3, Sns} from 'aws-cdk-lib/aws-ses-actions';
import {Topic} from 'aws-cdk-lib/aws-sns';
import {Construct} from 'constructs';
import {PrivateBucketConstruct} from "./private-bucket-construct";
import {RemovalPolicy} from "aws-cdk-lib";
import {Bucket} from "aws-cdk-lib/aws-s3";

type SesConstructProps = {
    domain: string,
    sandboxToEmail: string,
    emailBucketName: string
};

export class SesConstruct extends Construct {
    public readonly helpEmailReceivedTopic: Topic;
    public readonly emailBucket: Bucket;
    public readonly s3EmailReceivedTopic: Topic;
    constructor(scope: Construct, id: string, props: SesConstructProps) {
        super(scope, id);
        new EmailIdentity(this, 'DomainIdentity', {
            identity: Identity.domain(props.domain)
        });
        new EmailIdentity(this, 'SandboxToIdentity', {
            identity: Identity.email(props.sandboxToEmail)
        });
        this.helpEmailReceivedTopic = new Topic(this, 'EmailReceivedTopic');
        this.helpEmailReceivedTopic.grantPublish(new ServicePrincipal('ses.amazonaws.com'));
        const emailBucket = new PrivateBucketConstruct(this, 'EmailBucket', {
            bucketName: props.emailBucketName,
            versioned: false,
            autoDeleteObjects: true,
            removalPolicy: RemovalPolicy.DESTROY
        });
        emailBucket.bucket.grantPut(new ServicePrincipal('ses.amazonaws.com'));
        this.s3EmailReceivedTopic = new Topic(this, 'S3EmailReceivedTopic');
        this.s3EmailReceivedTopic.grantPublish(new ServicePrincipal('ses.amazonaws.com'));
        this.emailBucket = emailBucket.bucket;
        // Has to be activated from CLI
        new ReceiptRuleSet(this, 'RuleSet', {
            receiptRuleSetName: 'forward-to-sns-rule-set',
            rules: [
                {
                    recipients: [`help@${props.domain}`],
                    actions: [
                        new Sns({
                            topic: this.helpEmailReceivedTopic
                        })
                    ]
                },
                {
                    recipients: [`excel@${props.domain}`],
                    actions: [
                        new S3({
                            bucket: emailBucket.bucket,
                            topic: this.s3EmailReceivedTopic
                        })
                    ]
                }
            ]
        });
    }
}