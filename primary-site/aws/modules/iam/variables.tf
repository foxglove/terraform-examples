variable "lake_bucket_arn" {
  type        = string
  description = "ARN of the lake S3 bucket"
}

variable "inbox_bucket_arn" {
  type        = string
  description = "ARN of the inbox S3 bucket"
}

variable "iam_user_name" {
  type        = string
  description = "Name of the IAM user to be created"
}
