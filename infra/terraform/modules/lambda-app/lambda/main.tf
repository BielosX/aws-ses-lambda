data "aws_iam_policy_document" "lambda-assume-role" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda-role" {
  assume_role_policy = data.aws_iam_policy_document.lambda-assume-role.json
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSESFullAccess",
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  ]
}

locals {
  help-lambda-name = "help-lambda"
  welcome-lambda-name = "welcome-lambda"
  lambdas = {
    (local.welcome-lambda-name) = "LambdaInvocationHandler::handleRequest"
    (local.help-lambda-name) = "HelpEmailHandler::handleRequest"
  }
}

resource "aws_lambda_function" "lambda" {
  for_each = local.lambdas
  function_name = each.key
  role = aws_iam_role.lambda-role.arn
  runtime = "java17"
  handler = each.value
  s3_bucket = var.artifact-bucket-arn
  s3_key = var.artifact-name
  timeout = 60
  memory_size = 1024
  environment {
    variables = {
      FROM_DOMAIN: var.ses-domain
    }
  }
}

resource "aws_lambda_permission" "sns-invoke-permission" {
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda[local.help-lambda-name].function_name
  principal = "sns.amazonaws.com"
}

resource "aws_sns_topic_subscription" "help-lambda-subscription" {
  endpoint = aws_lambda_function.lambda[local.help-lambda-name].arn
  protocol = "lambda"
  topic_arn = var.email-received-topic-arn
}
