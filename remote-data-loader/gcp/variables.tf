variable "gcp_project" {
  type        = string
  description = "Name of the GCP project"
}

variable "gcp_region" {
  type        = string
  description = "Region of the GCP project"
}

variable "cache_bucket_name" {
  type        = string
  description = "Bucket name to be used for cache storage"
}

variable "cache_expiration_days" {
  type        = number
  description = "Number of days after which cached objects are deleted"
  default     = 30
}

variable "service_account_name" {
  type        = string
  description = "Name of the service account with access to the cache bucket"
}

variable "vpc_name" {
  type        = string
  description = "Name of the VPC network"
}

variable "cluster_name" {
  type        = string
  description = "Name of the Autopilot cluster"
}
