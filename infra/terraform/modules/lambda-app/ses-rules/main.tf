resource "aws_ses_receipt_rule_set" "rule-set" {
  rule_set_name = "rule-set"
}

// Requires adding MX record
// https://docs.aws.amazon.com/ses/latest/dg/receiving-email-mx-record.html
resource "aws_ses_receipt_rule" "email-sns-rule" {
  name = "sns-rule"
  recipients = ["help@${var.ses-domain}"]
  enabled = true
  scan_enabled = true
  rule_set_name = aws_ses_receipt_rule_set.rule-set.id
  // Email size up to 150KB https://docs.aws.amazon.com/ses/latest/dg/receiving-email-action-sns.html
  // For bigger use S3
  sns_action {
    position = 1
    topic_arn = var.email-received-topic-arn
  }
}

resource "aws_ses_receipt_rule" "email-s3-rule" {
  name = "s3-rule"
  rule_set_name = aws_ses_receipt_rule_set.rule-set.id
  enabled = true
  scan_enabled = true
  recipients = ["excel@${var.ses-domain}"]
  s3_action {
    position = 1
    bucket_name = var.email-bucket-name
    object_key_prefix = "excel/"
    topic_arn = var.email-uploaded-topic-arn
  }
}

resource "aws_ses_receipt_rule" "blocking-rule" {
  name = "blocking-rule"
  rule_set_name = aws_ses_receipt_rule_set.rule-set.id
  enabled = true
  scan_enabled = true
  recipients = ["block@${var.ses-domain}"]
  lambda_action {
    function_arn = var.blocking-lambda-arn
    invocation_type = "RequestResponse"
    position = 1
  }
  s3_action {
    bucket_name = var.email-bucket-name
    object_key_prefix = "allowed/"
    position = 2
  }
}

resource "aws_ses_active_receipt_rule_set" "active-rule" {
  rule_set_name = aws_ses_receipt_rule_set.rule-set.id
}