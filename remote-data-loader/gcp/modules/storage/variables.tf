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
  description = "Name of the cache bucket"
}

variable "cache_expiration_days" {
  type        = number
  description = "Number of days after which cached objects are deleted"
  default     = 30
}
