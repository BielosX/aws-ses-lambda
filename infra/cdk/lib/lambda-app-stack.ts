import * as cdk from 'aws-cdk-lib';
import {Bucket} from 'aws-cdk-lib/aws-s3';
import {AttributeType, Table} from 'aws-cdk-lib/aws-dynamodb';
import {Construct} from 'constructs';
import {SesConstruct} from './ses-construct';
import {LambdaConstruct} from './lambda-construct';
import {Lambda, LambdaInvocationType, S3} from "aws-cdk-lib/aws-ses-actions";
import {IFunction} from "aws-cdk-lib/aws-lambda";

export class LambdaAppStack extends cdk.Stack {
    public readonly welcomeLambdaAliasArn: string;
    constructor(scope: Construct, id: string, props?: cdk.StackProps) {
        super(scope, id, props);
        const domain = this.node.tryGetContext('domain');
        const sandboxToEmail = this.node.tryGetContext('sandboxToEmail');
        const artifactName = this.node.tryGetContext('artifactName');
        const bucketName = cdk.Fn.importValue('artifacts-bucket-name');
        const artifactBucket = Bucket.fromBucketName(this, 'ArtifactsBcuket', bucketName);
        const dynamoTable = new Table(this, 'BlockedEmailsTable', {
            tableName: 'blocked-emails',
            partitionKey: {
                name: 'email',
                type: AttributeType.STRING
            }
        });
        const ses = new SesConstruct(this, 'Ses', {
            domain,
            sandboxToEmail,
            emailBucketName: `email-bucket-${this.region}-${this.account}`
        });
        const lambda = new LambdaConstruct(this, 'Lambda', {
            emailReceivedTopic: ses.helpEmailReceivedTopic,
            fromDomain: domain,
            artifactName,
            artifactBucket,
            emailBucketReceivedTopic: ses.s3EmailReceivedTopic,
            blockedEmailsTableName: dynamoTable.tableName
        });
        this.welcomeLambdaAliasArn = lambda.lambdaAliases.get(lambda.welcomeLambdaAliasName)?.functionArn as string;
        ses.ruleSet.addRule('BlockEmailsRule', {
            recipients: [`block@${domain}`],
            actions: [
                new Lambda({
                    function: lambda.lambdas.get(lambda.blockingLambdaName) as IFunction,
                    invocationType: LambdaInvocationType.REQUEST_RESPONSE
                }),
                new S3({
                    bucket: ses.emailBucket,
                    objectKeyPrefix: 'allowed/'
                })
            ]
        });
    }
}