locals {
  openapi-body = {
    openapi = "3.0.1"
    info = {
      title = "Email API"
      description = "Email API"
      version = "1.0"
    }
    paths = {
      "/welcome" = {
        post = {
          operationId: "Send Welcome Email"
          "x-amazon-apigateway-integration": {
            type: "AWS_PROXY"
            httpMethod: "POST"
            uri = var.welcome-lambda-arn
            payloadFormatVersion = "2.0"
          }
        }
      }
    }
  }
}

resource "aws_apigatewayv2_api" "api-gateway" {
  name = var.api-name
  protocol_type = "HTTP"
  body = jsonencode(local.openapi-body)
}

resource "aws_apigatewayv2_stage" "default-stage" {
  api_id = aws_apigatewayv2_api.api-gateway.id
  name = "$default"
  auto_deploy = true
}