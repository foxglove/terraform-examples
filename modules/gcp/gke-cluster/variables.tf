variable "gcp_project" {
  type        = string
  description = "Name of the GCP project"
}

variable "gcp_region" {
  type        = string
  description = "Region of the GCP project"
}

variable "vpc_name" {
  type        = string
  description = "Name of the VPC network"
}

variable "cluster_name" {
  type        = string
  description = "Name of the GKE Autopilot cluster"
}
