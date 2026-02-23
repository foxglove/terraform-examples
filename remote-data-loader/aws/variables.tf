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

variable "node_group_min_size" {
  type        = number
  description = "Minimum number of nodes in the EKS node group"
  default     = 0
}

variable "node_group_max_size" {
  type        = number
  description = "Maximum number of nodes in the EKS node group"
  default     = 2
}

variable "node_group_desired_size" {
  type        = number
  description = "Desired number of nodes in the EKS node group"
  default     = 1
}

variable "node_group_instance_types" {
  type        = list(string)
  description = "List of instance types for the EKS node group"
  default     = ["t3.small"]
}
