module "eks_garbage_collector_sa_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.60.0"
  
  role_name = "${var.eks_foxglove_namespace}-garbage-collector-sa-role"

  oidc_providers = {
    main = {
      provider_arn               = var.eks_oidc_provider_arn
      namespace_service_accounts = ["${var.eks_foxglove_namespace}:garbage-collector"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "foxglove_garbage_collector_policy_attachment" {
  # Note that garbage-collector uses the exact same policy as the inbox-listener
  policy_arn = aws_iam_policy.inbox_listener_policy.arn
  role       = module.eks_garbage_collector_sa_role.iam_role_name
}
