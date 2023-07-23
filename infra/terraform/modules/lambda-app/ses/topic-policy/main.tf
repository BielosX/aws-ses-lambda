data "aws_iam_policy_document" "sns-policy" {
  statement {
    sid = "ses-publish"
    effect = "Allow"
    actions = ["sns:Publish"]
    resources = [var.topic-arn]
    principals {
      type = "Service"
      identifiers = ["ses.amazonaws.com"]
    }
  }
  statement {
    sid = "lambda-subscribe"
    effect = "Allow"
    actions = ["sns:Subscribe", "sns:ListSubscriptionsByTopic"]
    resources = [var.topic-arn]
    principals {
      type = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}