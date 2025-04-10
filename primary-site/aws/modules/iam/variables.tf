variable "prefix" {
  description = "Prefix for naming resources"
  type        = string
}

variable "lake_bucket_arn" {
  type        = string
  description = "ARN of the lake S3 bucket"
}

variable "inbox_bucket_arn" {
  type        = string
  description = "ARN of the inbox S3 bucket"
}

variable "eks_oidc_provider_arn" {
  type        = string
  description = "ARN of the EKS cluster's OIDC provider"
}

variable "eks_foxglove_namespace" {
  type        = string
  description = "Namespace for Foxglove resources in K8S; required for the correct SA namespace_service_accounts config"
}
