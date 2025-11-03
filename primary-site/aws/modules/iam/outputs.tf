output "iam_inbox_listener_role_arn" {
  value       = module.eks_inbox_listener_sa_role.iam_role_arn
  description = "ARN for the role to be added to inbox listener pods"
}

output "iam_query_service_role_arn" {
  value       = module.eks_query_service_sa_role.iam_role_arn
  description = "ARN for the role to be added to query service pods"
}

output "iam_garbage_collector_role_arn" {
  value       = module.eks_garbage_collector_sa_role.iam_role_arn
  description = "ARN for the role to be added to garbage collector pods"
}
