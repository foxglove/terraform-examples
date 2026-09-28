output "eks_oidc_provider_arn" {
  value       = module.eks.oidc_provider_arn
  description = "ARN of the EKS OIDC provider"
}

output "eks_vpc_arn" {
  value       = module.vpc.vpc_arn
  description = "ARN of the EKS cluster's VPC"
}

output "iam_indexer_role_arn" {
  value       = module.iam.iam_indexer_role_arn
  description = "ARN for the role to be added to indexer pods"
}

output "iam_query_service_role_arn" {
  value       = module.iam.iam_query_service_role_arn
  description = "ARN for the role to be added to query service pods"
}
