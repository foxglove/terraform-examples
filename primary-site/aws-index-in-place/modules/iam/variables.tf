variable "indexed_bucket_arns" {
  type        = list(string)
  description = "ARNs of the S3 bucket(s) Foxglove indexes in place"
}

variable "eks_oidc_provider_arn" {
  type        = string
  description = "ARN of the EKS cluster's OIDC provider"
}

variable "eks_foxglove_namespace" {
  type        = string
  description = "Namespace for Foxglove resources in K8S; required for the correct SA namespace_service_accounts config"
}
