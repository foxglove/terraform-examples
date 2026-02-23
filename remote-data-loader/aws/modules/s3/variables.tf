variable "bucket_name" {
  type        = string
  description = "Name of the S3 bucket"
}

variable "cache_expiration_days" {
  type        = number
  description = "Number of days after which cached objects are deleted"
  default     = 30
}

variable "abort_incomplete_multipart_upload_days" {
  type        = number
  description = "Number of days after which incomplete multipart uploads are aborted"
  default     = 7
}
