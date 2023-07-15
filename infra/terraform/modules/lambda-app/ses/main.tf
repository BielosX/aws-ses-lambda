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


data "aws_iam_policy_document" "sns-policy" {
  statement {
    sid = "ses-publish"
    effect = "Allow"
    actions = ["sns:Publish"]
    resources = [aws_sns_topic.ses-email-received-topic.arn]
    principals {
      type = "Service"
      identifiers = ["ses.amazonaws.com"]
    }
  }
  statement {
    sid = "lambda-subscribe"
    effect = "Allow"
    actions = ["sns:Subscribe", "sns:ListSubscriptionsByTopic"]
    resources = [aws_sns_topic.ses-email-received-topic.arn]
    principals {
      type = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_sns_topic_policy" "sns-policy" {
  arn = aws_sns_topic.ses-email-received-topic.arn
  policy = data.aws_iam_policy_document.sns-policy.json
}

// Requires adding MX record
// https://docs.aws.amazon.com/ses/latest/dg/receiving-email-mx-record.html
resource "aws_ses_receipt_rule" "sns-rule" {
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

resource "aws_ses_active_receipt_rule_set" "active-rule" {
  rule_set_name = aws_ses_receipt_rule_set.rule-set.id
}