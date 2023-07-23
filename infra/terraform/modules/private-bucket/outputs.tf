output "bucket-name" {
  value = aws_s3_bucket.private-bucket.id
}

output "bucket-arn" {
  value = aws_s3_bucket.private-bucket.arn
}