variable "gcp_project" {
  type        = string
  description = "Name of the GCP project"
}

variable "gcp_region" {
  type        = string
  description = "Region of the GCP project"
}

variable "inbox_bucket_name" {
  type        = string
  description = "Bucket name to be used as inbox"
}

variable "lake_bucket_name" {
  type        = string
  description = "Bucket name to be used as lake"
}

variable "inbox_notification_endpoint" {
  type        = string
  description = "https endpoint to call on file upload"
}

variable "bucket_delete_days_since_noncurrent_time" {
  type        = number
  description = "Lifecycle rule to delete objects older than X days"
}

variable "bucket_delete_num_newer_version" {
  type        = number
  description = "Lifecycle rule to delete objects with over X older versions"
}
