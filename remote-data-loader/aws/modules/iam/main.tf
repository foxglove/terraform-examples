data "aws_iam_policy_document" "remote_data_loader_policy_document" {
  statement {
    actions = [
      "s3:ListBucket"
    ]
    resources = [var.cache_bucket_arn]
    effect    = "Allow"
  }

  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = [
      var.cache_bucket_arn,
      "${var.cache_bucket_arn}/*"
    ]
    effect = "Allow"
  }
}

resource "aws_iam_policy" "remote_data_loader_policy" {
  name   = "${var.eks_foxglove_namespace}-remote-data-loader-sa-policy"
  path   = "/"
  policy = data.aws_iam_policy_document.remote_data_loader_policy_document.json
}

module "eks_remote_data_loader_sa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.60.0"

  role_name = "${var.eks_foxglove_namespace}-remote-data-loader-sa-role"

  oidc_providers = {
    main = {
      provider_arn = var.eks_oidc_provider_arn
      namespace_service_accounts = [
        "${var.eks_foxglove_namespace}:remote-data-loader"
      ]
    }
  }
}

resource "aws_iam_role_policy_attachment" "remote_data_loader_policy_attachment" {
  policy_arn = aws_iam_policy.remote_data_loader_policy.arn
  role       = module.eks_remote_data_loader_sa_role.iam_role_name
}
