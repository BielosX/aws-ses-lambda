output "ses-domain" {
  value = aws_ses_domain_identity.ses-domain.id
}

output "email-received-topic-arn" {
  value = aws_sns_topic.ses-email-received-topic.arn
}

output "email-uploaded-topi-arn" {
  value = aws_sns_topic.email-uploaded-topic.arn
}