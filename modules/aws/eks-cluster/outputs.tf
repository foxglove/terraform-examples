output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "ID of the VPC"
}

output "vpc_arn" {
  value       = module.vpc.vpc_arn
  description = "ARN of the VPC"
}

output "private_subnets" {
  value       = module.vpc.private_subnets
  description = "List of private subnet IDs"
}

output "oidc_provider_arn" {
  value       = module.eks.oidc_provider_arn
  description = "ARN of the EKS OIDC provider"
}

output "cluster_name" {
  value       = module.eks.cluster_name
  description = "Name of the EKS cluster"
}
