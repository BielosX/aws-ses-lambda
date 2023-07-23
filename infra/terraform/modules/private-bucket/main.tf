data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  region = data.aws_region.current.name
  account-id = data.aws_caller_identity.current.account_id
}

resource "aws_s3_bucket" "private-bucket" {
  bucket = "${var.name-prefix}-${local.account-id}-${local.region}"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "private-bucket-access" {
  bucket = aws_s3_bucket.private-bucket.id
  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "private-bucket-ownership" {
  bucket = aws_s3_bucket.private-bucket.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

data "aws_iam_policy_document" "bucket-policy" {
  statement {
    effect = "Allow"
    actions = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.private-bucket.arn}/*"]
    principals {
      type = "Service"
      identifiers = var.services-grant-put
    }
  }
}

resource "aws_s3_bucket_policy" "bucket-policy" {
  count  = length(var.services-grant-put) > 0 ? 1 : 0
  bucket = aws_s3_bucket.private-bucket.id
  policy = data.aws_iam_policy_document.bucket-policy.json
}