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
