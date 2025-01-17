resource "aws_sqs_queue" "dlq" {
  name = "${var.topic_name}-sqs-dlq"
}

resource "aws_sns_topic" "topic" {
  name = var.topic_name
  delivery_policy = jsonencode({
    "http" : {
      "defaultHealthyRetryPolicy" : {
        "numRetries" : 100,
        "minDelayTarget" : 20, // In seconds; default is 20
        "maxDelayTarget" : 20, // In seconds; default is 20
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

data "aws_iam_policy_document" "sqs_dlq_policy" {
  policy_id = "__default_policy_ID"

  statement {
    actions = [
      "SQS:SendMessage"
    ]

    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }

    resources = [
      aws_sqs_queue.dlq.arn,
    ]

    condition {
      test     = "ArnEquals"
      values   = [aws_sns_topic.topic.arn]
      variable = "aws:SourceArn"
    }
  }
}

resource "aws_sqs_queue_policy" "allow_publish_from_sns" {
  queue_url = aws_sqs_queue.dlq.id
  policy    = data.aws_iam_policy_document.sqs_dlq_policy.json
}

resource "aws_sns_topic_subscription" "webhook" {
  topic_arn = aws_sns_topic.topic.arn
  protocol  = "https"
  endpoint  = var.inbox_notification_endpoint

  redrive_policy = jsonencode({
    "deadLetterTargetArn" : aws_sqs_queue.dlq.arn
  })
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
