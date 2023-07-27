import {Duration} from 'aws-cdk-lib';
import {ManagedPolicy, Role, ServicePrincipal} from 'aws-cdk-lib/aws-iam';
import {Alias, Code, Function, IAlias, IFunction, Runtime} from 'aws-cdk-lib/aws-lambda';
import {IBucket} from 'aws-cdk-lib/aws-s3';
import {ITopic} from 'aws-cdk-lib/aws-sns';
import {LambdaSubscription} from 'aws-cdk-lib/aws-sns-subscriptions';
import {Construct} from 'constructs';

type LambdaConstructProps = {
    emailReceivedTopic: ITopic,
    artifactBucket: IBucket,
    artifactName: string,
    fromDomain: string,
    emailBucketReceivedTopic: ITopic
};

export class LambdaConstruct extends Construct {
    public readonly lambdas: Map<string, IFunction>;
    public readonly lambdaAliases: Map<string, IAlias>;
    public readonly helpLambdaName = 'help-lambda';
    public readonly welcomeLambdaName = 'welcome-lambda';
    public readonly excelLambdaName = 'excel-lambda';
    public readonly welcomeLambdaAliasName = 'welcome-lambda-alias';
    constructor(scope: Construct, id: string, props: LambdaConstructProps) {
        super(scope, id);
        this.lambdas = new Map<string, IFunction>();
        this.lambdaAliases = new Map<string, IAlias>();
        const functionToHandler = new Map<string,string>(
            [
                [this.helpLambdaName, 'HelpEmailHandler::handleRequest'],
                [this.welcomeLambdaName, 'WelcomeEmailHandler::handleRequest'],
                [this.excelLambdaName, 'EmailUploadedHandler::handleRequest']
            ]
        );
        const lambdaRole = new Role(this, 'LambdaRole', {
            assumedBy: new ServicePrincipal('lambda.amazonaws.com'),
            managedPolicies: [
                ManagedPolicy.fromManagedPolicyArn(this,
                    'SESFullAccess',
                    'arn:aws:iam::aws:policy/AmazonSESFullAccess'),
                ManagedPolicy.fromManagedPolicyArn(this,
                    'S3ReadOnlyAccess',
                    'arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess'),
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
            this.lambdas.set(functionName, func);
            if (functionName === this.helpLambdaName) {
                props.emailReceivedTopic.addSubscription(new LambdaSubscription(func))
            }
            if (functionName === this.welcomeLambdaName) {
                const welcomeLambdaAlias = new Alias(this, 'LambdaAlias', {
                    aliasName: this.welcomeLambdaAliasName,
                    version: func.currentVersion,
                    provisionedConcurrentExecutions: 1
                });
                welcomeLambdaAlias.grantInvoke(new ServicePrincipal("apigateway.amazonaws.com"));
                this.lambdaAliases.set(this.welcomeLambdaAliasName, welcomeLambdaAlias);
            }
            if (functionName === this.excelLambdaName) {
                props.emailBucketReceivedTopic.addSubscription(new LambdaSubscription(func));
            }
        });
    }
}