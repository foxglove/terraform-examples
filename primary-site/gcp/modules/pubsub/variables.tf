variable "gcp_project" {
  type        = string
  description = "Name of the GCP project"
}

variable "bucket_name" {
  type        = string
  description = "Name of the bucket where the file upload notifications should be sent from"
}

variable "inbox_notification_endpoint" {
  type        = string
  description = "https endpoint to call on file upload"
}
