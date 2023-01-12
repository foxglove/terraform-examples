data "aws_iam_policy_document" "policy_document" {
  statement {
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket"
    ]
    resources = [
      var.lake_bucket_arn,
      var.inbox_bucket_arn,
    ]
    effect = "Allow"
  }
  statement {
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:AbortMultipartUpload",
      "s3:DeleteObject",
      "s3:DeleteObjectVersion",
      "s3:ListBucketMultipartUploads",
      "s3:ListMultipartUploadParts",
      "s3:PutObject"
    ]
    resources = [
      var.lake_bucket_arn,
      "${var.lake_bucket_arn}/*",
      var.inbox_bucket_arn,
      "${var.inbox_bucket_arn}/*",
    ]
    effect = "Allow"
  }
}

resource "aws_iam_policy" "policy" {
  name   = "${var.iam_user_name}-policy"
  path   = "/"
  policy = data.aws_iam_policy_document.policy_document.json
}

# Admin user for Terraform to access this sub-org
resource "aws_iam_user" "iam_user" {
  name          = var.iam_user_name
  path          = "/"
  force_destroy = true
}

resource "aws_iam_access_key" "iam_user_key" {
  depends_on = [
    aws_iam_user.iam_user
  ]
  user = var.iam_user_name
}

resource "aws_iam_policy_attachment" "policy_attachment" {
  name       = "${var.iam_user_name}-policy-attachment"
  users      = [aws_iam_user.iam_user.name]
  policy_arn = aws_iam_policy.policy.arn
}
