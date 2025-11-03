output "eks_oidc_provider_arn" {
  value       = module.eks.oidc_provider_arn
  description = "ARN of the EKS OIDC provider"
}

output "eks_vpc_arn" {
  value       = module.vpc.vpc_arn
  description = "VPC ID of the EKS cluster"
}

output "iam_inbox_listener_role_arn" {
  value       = module.iam.iam_inbox_listener_role_arn
  description = "ARN for the role to be added to inbox listener pods"
}

output "iam_query_service_role_arn" {
  value       = module.iam.iam_query_service_role_arn
  description = "ARN for the role to be added to query service pods"
}

output "iam_garbage_collector_role_arn" {
  value       = module.iam.iam_garbage_collector_role_arn
  description = "ARN for the role to be added to garbage collector pods"
}
