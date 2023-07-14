terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.7.0"
    }
  }
  backend "s3" {
    key = "artifacts-bucket.tfstate"
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
  force_destroy = true
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