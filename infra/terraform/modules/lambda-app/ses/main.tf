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

resource "aws_sns_topic" "ses-email-received-topic" {
  name = "ses-email-received-topic"
}

resource "aws_sns_topic" "email-uploaded-topic" {
  name = "email-uploaded-topic"
}

module "sns-topic-policy" {
  source = "./topic-policy"
  topic-arn = aws_sns_topic.ses-email-received-topic.arn
}

module "email-uploaded-topic-policy" {
  source = "./topic-policy"
  topic-arn = aws_sns_topic.email-uploaded-topic.arn
}

resource "aws_sns_topic_policy" "sns-policy" {
  arn = aws_sns_topic.ses-email-received-topic.arn
  policy = module.sns-topic-policy.json
}

resource "aws_sns_topic_policy" "s3-uploaded-topic-policy" {
  arn = aws_sns_topic.email-uploaded-topic.arn
  policy = module.email-uploaded-topic-policy.json
}