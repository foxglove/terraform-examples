variable "gcp_project" {
  type        = string
  description = "Name of the GCP project"
}

variable "gcp_region" {
  type        = string
  description = "Region of the GCP project"
}

variable "bucket_name" {
  type        = string
  description = "Name of the created bucket"
}

variable "bucket_delete_days_since_noncurrent_time" {
  type        = number
  description = "Lifecycle rule to delete objects older than X days"
}

variable "bucket_delete_num_newer_version" {
  type        = number
  description = "Lifecycle rule to delete objects with over X older versions"
}
