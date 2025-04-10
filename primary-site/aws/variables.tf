variable "inbox_notification_endpoint" {
  type        = string
  description = "https endpoint to call on file upload"
}

variable "abort_incomplete_multipart_upload_days" {
  type        = number
  description = "Number of days a multipart upload needs to be completed within"
}

variable "prefix" {
  description = "Prefix for naming resources"
  type        = string
}

variable "site_token" {
  description = "Site token for API endpoint"
  type        = string
  sensitive   = true
}

variable "route53_zone_id" {
  description = "The ID of the Route53 hosted zone"
  type        = string
}

variable "route53_zone_name" {
  description = "The name of the Route53 hosted zone (e.g., example.com)"
  type        = string
}

variable "eks_node_group_min_size" {
  description = "Minimum number of nodes in the EKS node group"
  type        = number
  default     = 0
}

variable "eks_node_group_max_size" {
  description = "Maximum number of nodes in the EKS node group"
  type        = number
  default     = 5
}

variable "eks_node_group_desired_size" {
  description = "Desired number of nodes in the EKS node group"
  type        = number
  default     = 1
}

variable "eks_node_instance_types" {
  description = "List of instance types for the EKS node group"
  type        = list(string)
  default     = ["t3.small"]
}

variable "enable_monitoring" {
  description = "Whether to install Prometheus and related monitoring components"
  type        = bool
  default     = false
}
