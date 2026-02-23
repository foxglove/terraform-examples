variable "aws_region" {
  type        = string
  description = "AWS region to deploy resources"
  default     = "us-east-1"
}

variable "cache_bucket_name" {
  type        = string
  description = "S3 bucket to be used for cache storage"
}

variable "cache_expiration_days" {
  type        = number
  description = "Number of days after which cached objects are deleted"
  default     = 30
}

variable "abort_incomplete_multipart_upload_days" {
  type        = number
  description = "Number of days after which incomplete multipart uploads are aborted"
  default     = 7
}

variable "vpc_name" {
  type        = string
  description = "Name of the VPC"
}

variable "eks_cluster_name" {
  type        = string
  description = "Name of the EKS cluster"
}

variable "eks_cluster_version" {
  type        = string
  description = "EKS cluster version"
  default     = "1.31"
}

variable "eks_foxglove_namespace" {
  type        = string
  description = "Kubernetes namespace for Remote Data Loader resources"
  default     = "foxglove"
}
