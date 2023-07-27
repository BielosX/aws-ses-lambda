import * as cdk from 'aws-cdk-lib';
import {Construct} from "constructs";
import {ApiGatewayV2Construct} from "./api-gateway-v2-construct";

type ApiGatewayV2StackProps = {
    welcomeLambdaAliasArn: string
};

export class ApiGatewayV2Stack extends cdk.Stack {
    constructor(scope: Construct, id: string, apiGatewayProps: ApiGatewayV2StackProps, props?: cdk.StackProps) {
        super(scope, id, props);
        new ApiGatewayV2Construct(this, 'ApiGatewayV2', {
            welcomeLambdaAliasArn: apiGatewayProps.welcomeLambdaAliasArn
        });
    }
}