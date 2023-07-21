import {Construct} from "constructs";
import {aws_apigatewayv2 as apigatewayv2} from 'aws-cdk-lib';
import {IFunction} from "aws-cdk-lib/aws-lambda";
import {ServicePrincipal} from "aws-cdk-lib/aws-iam";

type ApiGatewayV2ConstructProps = {
    welcomeLambda: IFunction
};

export class ApiGatewayV2Construct extends Construct {
    constructor(scope: Construct, id: string, props: ApiGatewayV2ConstructProps) {
        super(scope, id);
        props.welcomeLambda.grantInvoke(new ServicePrincipal('apigateway.amazonaws.com'));
        const cfnApi = new apigatewayv2.CfnApi(this, 'ApiGatewayV2', {
            body: {
                openapi: '3.0.1',
                info: {
                    title: 'Email API',
                    description: 'Email API',
                    version: '1.0'
                },
                paths: {
                    '/welcome': {
                        post: {
                            operationId: 'Send Welcome email',
                            'x-amazon-apigateway-integration': {
                                type: 'AWS_PROXY', // Dedicated Lambda type
                                httpMethod: 'POST',
                                uri: props.welcomeLambda.functionArn,
                                payloadFormatVersion: '2.0'
                            }
                        }
                    }
                }
            }
        });
        new apigatewayv2.CfnStage(this, 'DefaultStage', {
            apiId: cfnApi.attrApiId,
            stageName: '$default',
            autoDeploy: true
        });
    }
}