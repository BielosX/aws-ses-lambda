import { Duration } from 'aws-cdk-lib';
import { ManagedPolicy, Role, ServicePrincipal } from 'aws-cdk-lib/aws-iam';
import { Code, Function, Runtime } from 'aws-cdk-lib/aws-lambda';
import { IBucket } from 'aws-cdk-lib/aws-s3';
import { Topic } from 'aws-cdk-lib/aws-sns';
import { LambdaSubscription } from 'aws-cdk-lib/aws-sns-subscriptions';
import { Construct } from 'constructs';

type LambdaConstructProps = {
    emailReceivedTopic: Topic,
    artifactBucket: IBucket,
    artifactName: string,
    fromDomain: string
};

export class LambdaConstruct extends Construct {
    constructor(scope: Construct, id: string, props: LambdaConstructProps) {
        super(scope, id);
        const functionToHandler = new Map<string,string>(
            [
                ['help-lambda', 'HelpEmailHandler::handleRequest'],
                ['welcome-lambda', 'LambdaInvocationHandler::handleRequest']
            ]
        );
        const lambdaRole = new Role(this, 'LambdaRole', {
            assumedBy: new ServicePrincipal('lambda.amazonaws.com'),
            managedPolicies: [
                ManagedPolicy.fromManagedPolicyArn(this,
                    'SESFullAccess',
                    'arn:aws:iam::aws:policy/AmazonSESFullAccess'),
                ManagedPolicy.fromManagedPolicyArn(this,
                    'BasicExecutionRole',
                    'arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole')
            ]
        });
        functionToHandler.forEach((functionHandler, functionName) => {
            const func = new Function(this, functionName, {
                functionName,
                runtime: Runtime.JAVA_17,
                handler: functionHandler,
                code: Code.fromBucket(props.artifactBucket, props.artifactName),
                timeout: Duration.minutes(1),
                memorySize: 1024,
                role: lambdaRole,
                environment: {
                    FROM_DOMAIN: props.fromDomain
                }
            });
            if (functionName === 'help-lambda') {
                props.emailReceivedTopic.addSubscription(new LambdaSubscription(func))
            }
        });
    }
}