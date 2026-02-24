output "cache_bucket_name" {
  value       = module.s3_cache.bucket_name
  description = "Name of the cache S3 bucket"
}

output "cache_bucket_arn" {
  value       = module.s3_cache.bucket_arn
  description = "ARN of the cache S3 bucket"
}

output "eks_cluster_name" {
  value       = module.eks.cluster_name
  description = "Name of the EKS cluster"
}

output "eks_cluster_endpoint" {
  value       = module.eks.cluster_endpoint
  description = "Endpoint of the EKS cluster"
}

output "eks_oidc_provider_arn" {
  value       = module.eks.oidc_provider_arn
  description = "ARN of the EKS OIDC provider"
}

output "iam_remote_data_loader_role_arn" {
  value       = module.iam.iam_role_arn
  description = "ARN for the IAM role to be used by Remote Data Loader pods"
}
