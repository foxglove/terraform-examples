# AWS Load Balancer Controller IAM Policy
resource "aws_iam_policy" "aws_load_balancer_controller_policy" {
  name        = "AWSLoadBalancerControllerIAMPolicy"
  description = "IAM policy for AWS Load Balancer Controller"
  policy      = file("${path.module}/iam_policy.json")
}

# Service Account Role for AWS Load Balancer Controller
module "eks_aws_load_balancer_controller_sa_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.60.0"
  
  role_name = "aws-load-balancer-controller"

  oidc_providers = {
    main = {
      provider_arn               = var.eks_oidc_provider_arn
      namespace_service_accounts = ["foxglove:aws-load-balancer-controller"]
    }
  }
}

# Attach the policy to the role
resource "aws_iam_role_policy_attachment" "aws_load_balancer_controller_policy_attachment" {
  policy_arn = aws_iam_policy.aws_load_balancer_controller_policy.arn
  role       = module.eks_aws_load_balancer_controller_sa_role.iam_role_name
}