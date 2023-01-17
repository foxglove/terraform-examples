variable "gcp_project" {
  type        = string
  description = "Name of the GCP project"
}

variable "lake_bucket_name" {
  type        = string
  description = "Name of the lake bucket"
}

variable "inbox_bucket_name" {
  type        = string
  description = "Name of the inbox bucket"
}

variable "iam_user_name" {
  type        = string
  description = "Name of the IAM user to be created"
}
