variable "indexed_bucket_names" {
  type        = list(string)
  description = "Existing S3 bucket(s) to index in place"
}

variable "create_indexed_buckets" {
  type        = bool
  description = "Create the buckets in indexed_bucket_names. If false, they must already exist"
  default     = false
}

variable "bucket_notification_endpoint" {
  type        = string
  description = "https endpoint to call on file upload"
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
  default     = "1.35"
}
