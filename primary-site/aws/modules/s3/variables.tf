variable "bucket_name" {
  type        = string
  description = "Name of the S3 bucket"
}

variable "abort_incomplete_multipart_upload_days" {
  type        = number
  description = "Number of days a multipart upload needs to be completed within"
}
