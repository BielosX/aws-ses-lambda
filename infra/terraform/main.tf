terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.7.0"
    }
  }
}

provider "aws" {}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  region = data.aws_region.current.name
  account-id = data.aws_caller_identity.current.account_id
}

resource "aws_ses_domain_identity" "ses-domain" {
  domain = var.ses-domain
}

resource "aws_ses_domain_dkim" "dkim" {
  domain = aws_ses_domain_identity.ses-domain.id
}

resource "aws_route53_zone" "zone" {
  name = var.ses-domain
}

resource "aws_route53_record" "dkim-record" {
  count = 3
  zone_id = aws_route53_zone.zone.id
  name = "${aws_ses_domain_dkim.dkim.dkim_tokens[count.index]}._domainkey"
  type = "CNAME"
  ttl = "600"
  records = ["${aws_ses_domain_dkim.dkim.dkim_tokens[count.index]}.dkim.amazonses.com"]
}

resource "aws_ses_domain_identity_verification" "example_verification" {
  domain = aws_ses_domain_identity.ses-domain.id
  depends_on = [aws_route53_record.dkim-record]
}

// In Sandbox mode only sending to verified emails is possible
resource "aws_ses_email_identity" "sandbox-to-email" {
  email = var.sandbox-to-email
}

resource "aws_s3_bucket" "artifacts-bucket" {
  bucket = "artifacts-${local.account-id}-${local.region}"
}

resource "aws_s3_bucket_public_access_block" "artifacts-bucket-access" {
  bucket = aws_s3_bucket.artifacts-bucket.id
  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "artifacts-bucket-ownership" {
  bucket = aws_s3_bucket.artifacts-bucket.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_object" "jar-file" {
  bucket = aws_s3_bucket.artifacts-bucket.id
  key = var.artifact-name
  source = var.jar-file-path
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

resource "aws_lambda_function" "welcome-lambda" {
  function_name = "welcome-lambda"
  role = aws_iam_role.lambda-role.arn
  runtime = "java17"
  handler = "LambdaInvocationHandler::handleRequest"
  s3_bucket = aws_s3_bucket.artifacts-bucket.id
  s3_key = aws_s3_object.jar-file.id
  timeout = 60
  memory_size = 1024
  environment {
    variables = {
      FROM_DOMAIN: aws_ses_domain_identity.ses-domain.id
    }
  }
}