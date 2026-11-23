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

output "cloudfront_domain_name" {
  value       = one(module.cloudfront[*].domain_name)
  description = "Domain name of the CloudFront distribution, when enabled"
}

output "cloudfront_hosted_zone_id" {
  value       = one(module.cloudfront[*].hosted_zone_id)
  description = "Route 53 hosted zone ID for alias records that point at the CloudFront distribution, when enabled"
}
