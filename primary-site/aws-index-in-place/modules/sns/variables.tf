variable "topic_name" {
  type        = string
  description = "Name of the SNS topic"
}

variable "bucket_id" {
  type        = string
  description = "ID of the S3 bucket that will send ObjectCreated events to the topic"
}

variable "bucket_arn" {
  type        = string
  description = "ARN of the S3 bucket that will send ObjectCreated events to the topic"
}

variable "inbox_notification_endpoint" {
  type        = string
  description = "https endpoint to call on file upload"
}
