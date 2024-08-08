# inbox listener should be able to get, delete, list and put objects into the lake and inbox S3 buckets
data "aws_iam_policy_document" "inbox_listener_policy_document" {
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

resource "aws_iam_policy" "inbox_listener_policy" {
  name = "${var.eks_foxglove_namespace}-inbox-listener-sa-policy"
  path   = "/"
  policy = data.aws_iam_policy_document.inbox_listener_policy_document.json
}

module "eks_inbox_listener_sa_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name = "${var.eks_foxglove_namespace}-inbox-listener-sa-role"

  oidc_providers = {
    main = {
      provider_arn               = var.eks_oidc_provider_arn
      namespace_service_accounts = ["${var.eks_foxglove_namespace}:inbox-listener"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "foxglove_inbox_listener_policy_attachment" {
  policy_arn = aws_iam_policy.inbox_listener_policy.arn
  role       = module.eks_inbox_listener_sa_role.iam_role_name
}
