data "aws_iam_policy_document" "stream_service_policy_document" {
  statement {
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket"
    ]
    resources = [var.lake_bucket_arn]
    effect = "Allow"
  }
  statement {
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion"
    ]
    # Read access to the inbox is provided to serve quarantined files
    resources = [
      var.lake_bucket_arn,
      "${var.lake_bucket_arn}/*",
      var.inbox_bucket_arn,
      "${var.inbox_bucket_arn}/*",
    ]
    effect = "Allow"
  }
}

resource "aws_iam_policy" "stream_service_policy" {
  name = "${var.eks_foxglove_namespace}-stream-service-sa-policy"
  path   = "/"
  policy = data.aws_iam_policy_document.stream_service_policy_document.json
}

module "eks_stream_service_sa_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name = "${var.eks_foxglove_namespace}-stream-service-sa-role"

  oidc_providers = {
    main = {
      provider_arn               = var.eks_oidc_provider_arn
      namespace_service_accounts = ["${var.eks_foxglove_namespace}:stream-service"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "foxglove_stream_service_policy_attachment" {
  policy_arn = aws_iam_policy.stream_service_policy.arn
  role       = module.eks_stream_service_sa_role.iam_role_name
}
