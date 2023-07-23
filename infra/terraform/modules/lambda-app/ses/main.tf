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

resource "aws_ses_receipt_rule_set" "rule-set" {
  rule_set_name = "rule-set"
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

// Requires adding MX record
// https://docs.aws.amazon.com/ses/latest/dg/receiving-email-mx-record.html
resource "aws_ses_receipt_rule" "email-sns-rule" {
  depends_on = [aws_sns_topic_policy.sns-policy]
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

resource "aws_ses_receipt_rule" "email-s3-rule" {
  depends_on = [aws_sns_topic_policy.s3-uploaded-topic-policy]
  name = "s3-rule"
  rule_set_name = aws_ses_receipt_rule_set.rule-set.id
  enabled = true
  scan_enabled = true
  recipients = ["excel@${var.ses-domain}"]
  s3_action {
    position = 1
    bucket_name = var.email-bucket-name
    topic_arn = aws_sns_topic.email-uploaded-topic.arn
  }
}

resource "aws_ses_active_receipt_rule_set" "active-rule" {
  rule_set_name = aws_ses_receipt_rule_set.rule-set.id
}