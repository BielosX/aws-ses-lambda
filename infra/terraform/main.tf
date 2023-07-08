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
    "arn:aws:iam::aws:policy/AmazonSESFullAccess"
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
}