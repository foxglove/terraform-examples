variable "cache_bucket_arn" {
  type        = string
  description = "ARN of the cache S3 bucket"
}

variable "eks_oidc_provider_arn" {
  type        = string
  description = "ARN of the EKS cluster's OIDC provider"
}

variable "eks_foxglove_namespace" {
  type        = string
  description = "Kubernetes namespace for Remote Data Loader resources"
}
