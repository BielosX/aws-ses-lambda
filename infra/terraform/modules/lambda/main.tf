terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.7.0"
    }
  }
  backend "s3" {
    key = "lambda.tfstate"
  }
}

provider "aws" {}

resource "aws_ses_domain_identity" "ses-domain" {
  domain = var.ses-domain
}

resource "aws_ses_domain_dkim" "dkim" {
  domain = aws_ses_domain_identity.ses-domain.id
}

// In Sandbox mode only sending to verified emails is possible
resource "aws_ses_email_identity" "sandbox-to-email" {
  email = var.sandbox-to-email
}

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
      FROM_DOMAIN: aws_ses_domain_identity.ses-domain.id
    }
  }
}

resource "aws_ses_receipt_rule_set" "rule-set" {
  rule_set_name = "rule-set"
}

resource "aws_sns_topic" "ses-email-received-topic" {
  name = "ses-email-received-topic"
}

data "aws_iam_policy_document" "sns-policy" {
  statement {
    sid = "ses-publish"
    effect = "Allow"
    actions = ["sns:Publish"]
    resources = [aws_sns_topic.ses-email-received-topic.arn]
    principals {
      type = "Service"
      identifiers = ["ses.amazonaws.com"]
    }
  }
  statement {
    sid = "lambda-subscribe"
    effect = "Allow"
    actions = ["sns:Subscribe", "sns:ListSubscriptionsByTopic"]
    resources = [aws_sns_topic.ses-email-received-topic.arn]
    principals {
      type = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_sns_topic_policy" "sns-policy" {
  arn = aws_sns_topic.ses-email-received-topic.arn
  policy = data.aws_iam_policy_document.sns-policy.json
}

// Requires adding MX record
// https://docs.aws.amazon.com/ses/latest/dg/receiving-email-mx-record.html
resource "aws_ses_receipt_rule" "sns-rule" {
  name = "sns-rule"
  recipients = ["help@${var.ses-domain}"]
  enabled = true
  scan_enabled = true
  rule_set_name = aws_ses_receipt_rule_set.rule-set.id
  // Email size up to 150KB https://docs.aws.amazon.com/ses/latest/dg/receiving-email-action-sns.html
  // For bigger use S3
  sns_action {
    position = 1
    topic_arn = aws_sns_topic.ses-email-received-topic.arn
  }
}

resource "aws_ses_active_receipt_rule_set" "active-rule" {
  rule_set_name = aws_ses_receipt_rule_set.rule-set.id
}

resource "aws_lambda_permission" "sns-invoke-permission" {
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda[local.help-lambda-name].function_name
  principal = "sns.amazonaws.com"
}

resource "aws_sns_topic_subscription" "help-lambda-subscription" {
  endpoint = aws_lambda_function.lambda[local.help-lambda-name].arn
  protocol = "lambda"
  topic_arn = aws_sns_topic.ses-email-received-topic.arn
}
