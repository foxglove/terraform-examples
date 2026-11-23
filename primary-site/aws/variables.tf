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

variable "vpc_name" {
  type        = string
  description = "Name of the VPC"
}

variable "eks_cluster_name" {
  type        = string
  description = "Name of the EKS cluster"
}

variable "abort_incomplete_multipart_upload_days" {
  type        = number
  description = "Number of days a multipart upload needs to be completed within"
}

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "eks_cluster_version" {
  description = "EKS cluster version"
  type        = string
  default     = "1.27"
}

variable "enable_cloudfront" {
  description = "Put a CloudFront distribution in front of the site's ALB. Requires site_load_balancer_name, site_hostname and cloudfront_certificate_arn."
  type        = bool
  default     = false
}

variable "site_load_balancer_name" {
  description = "Name of the site's ALB, set with the alb.ingress.kubernetes.io/load-balancer-name annotation on the primary site's Ingress"
  type        = string
  default     = null

  validation {
    condition     = var.site_load_balancer_name == null || can(regex("^[a-zA-Z0-9]([a-zA-Z0-9-]{0,30}[a-zA-Z0-9])?$", var.site_load_balancer_name))
    error_message = "site_load_balancer_name must be 1 to 32 letters, digits or hyphens, and can't start or end with a hyphen."
  }
}

variable "site_hostname" {
  description = "Hostname clients use to reach the site, matching the Ingress host"
  type        = string
  default     = null
}

variable "cloudfront_certificate_arn" {
  description = "ARN of an ACM certificate in us-east-1 that covers site_hostname"
  type        = string
  default     = null
}
