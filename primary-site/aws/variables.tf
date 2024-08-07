variable "inbox_bucket_name" {
  type        = string
  description = "S3 bucket to be used as inbox"
}

variable "lake_bucket_name" {
  type        = string
  description = "S3 bucket to be used as lake"
}

variable "inbox_notification_endpoint" {
  type        = string
  description = "https endpoint to call on file upload"
}

variable "primarysite_iam_user_name" {
  type        = string
  description = "Name of the primary site's IAM user with programmatic access"
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
  description = "Kubernetes version of the EKS cluster"
  default     = "1.30"
}

variable "eks_node_count" {
  type = number
  default = 1
  description = "Number of nodes in the EKS cluster"
}

variable "eks_node_min_count" {
  type = number
  default = 1
  description = "Minimum number of nodes in the EKS cluster node pool"
}

variable "eks_node_max_count" {
  type = number
  default = 1
  description = "Maximum number of nodes in the EKS cluster"
}

variable "eks_node_instance_type" {
  type = string
  default = "t3.small"
}

variable "abort_incomplete_multipart_upload_days" {
  type        = number
  description = "Number of days a multipart upload needs to be completed within"
}
