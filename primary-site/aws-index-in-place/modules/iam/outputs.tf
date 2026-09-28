output "iam_indexer_role_arn" {
  value       = module.eks_indexer_sa_role.iam_role_arn
  description = "ARN for the role to be added to indexer pods"
}

output "iam_query_service_role_arn" {
  value       = module.eks_query_service_sa_role.iam_role_arn
  description = "ARN for the role to be added to query service pods"
}
