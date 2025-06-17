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

variable "abort_incomplete_multipart_upload_days" {
  type        = number
  description = "Number of days a multipart upload needs to be completed within"
}

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "eks_cluster_version" {
  description = "EKS cluster version"
  type        = string
  default     = "1.27"
}
