output "eks_oidc_provider_arn" {
  value       = module.eks.oidc_provider_arn
  description = "ARN of the EKS OIDC provider"
}

output "eks_vpc_arn" {
  value       = module.vpc.vpc_arn
  description = "VPC ID of the EKS cluster"
}