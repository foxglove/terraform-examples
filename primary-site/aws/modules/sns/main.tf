resource "aws_sns_topic" "topic" {
  name = var.topic_name
  delivery_policy = jsonencode({
    "http" : {
      "defaultHealthyRetryPolicy" : {
        "numRetries" : 100,
      }
    }
  })
}

data "aws_iam_policy_document" "sns_topic_policy" {
  policy_id = "__default_policy_ID"

  statement {
    actions = [
      "SNS:Publish",
    ]

    condition {
      test     = "ArnLike"
      variable = "AWS:SourceArn"

      values = [
        var.bucket_arn
      ]
    }

    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    resources = [
      aws_sns_topic.topic.arn,
    ]

    sid = "__default_statement_ID"
  }
}

resource "aws_sns_topic_policy" "default" {
  arn    = aws_sns_topic.topic.arn
  policy = data.aws_iam_policy_document.sns_topic_policy.json
}

resource "aws_sns_topic_subscription" "webhook" {
  topic_arn = aws_sns_topic.topic.arn
  protocol  = "https"
  endpoint  = var.inbox_notification_endpoint
}

resource "aws_s3_bucket_notification" "s3_notification" {
  depends_on = [
    aws_sns_topic_policy.default
  ]
  bucket = var.bucket_id

  topic {
    topic_arn = aws_sns_topic.topic.arn

    events = [
      "s3:ObjectCreated:*",
    ]
  }
}
