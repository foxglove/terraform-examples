variable "gcp_project" {
  type        = string
  description = "Name of the GCP project"
}

variable "service_account_name" {
  type        = string
  description = "Name of the service account to be created"
}

variable "cache_bucket_name" {
  type        = string
  description = "Name of the cache bucket"
}
