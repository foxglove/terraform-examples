output "iam_role_arn" {
  value       = module.eks_remote_data_loader_sa_role.iam_role_arn
  description = "ARN for the IAM role to be used by Remote Data Loader pods"
}
