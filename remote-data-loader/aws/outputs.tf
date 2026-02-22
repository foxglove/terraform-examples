output "eks_oidc_provider_arn" {
  value       = module.cluster.oidc_provider_arn
  description = "ARN of the EKS OIDC provider"
}

output "eks_vpc_arn" {
  value       = module.cluster.vpc_arn
  description = "ARN of the VPC"
}

output "iam_remote_data_loader_role_arn" {
  value       = module.iam.iam_remote_data_loader_role_arn
  description = "ARN for the role to be added to remote data loader pods"
}
