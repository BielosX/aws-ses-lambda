output "bucket-name" {
  value = aws_s3_bucket.artifacts-bucket.id
}

output "bucket-arn" {
  value = aws_s3_bucket.artifacts-bucket.arn
}