variable "gcp_project" {
  type        = string
  description = "Name of the GCP project"
}

variable "cache_bucket_name" {
  type        = string
  description = "Name of the cache bucket"
}

variable "iam_user_name" {
  type        = string
  description = "Name of the IAM user to be created"
}
