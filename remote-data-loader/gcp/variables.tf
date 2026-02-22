variable "gcp_project" {
  type        = string
  description = "Name of the GCP project"
}

variable "gcp_region" {
  type        = string
  description = "Region of the GCP project"
}

variable "cache_bucket_name" {
  type        = string
  description = "Bucket name to be used as cache for the remote data loader"
}

variable "bucket_delete_days_since_noncurrent_time" {
  type        = number
  description = "Lifecycle rule to delete objects older than X days"
}

variable "bucket_delete_num_newer_version" {
  type        = number
  description = "Lifecycle rule to delete objects with over X older versions"
}

variable "iam_user_name" {
  type        = string
  description = "Name of the IAM service account with programmatic access"
}

variable "vpc_name" {
  type        = string
  description = "Name of the VPC network"
}

variable "cluster_name" {
  type        = string
  description = "Name of the Autopilot cluster"
}
