variable "load_balancer_dns_name" {
  type        = string
  description = "DNS name of the load balancer CloudFront sends requests to"
}

variable "site_hostname" {
  type        = string
  description = "Hostname clients use to reach the site"
}

variable "certificate_arn" {
  type        = string
  description = "ARN of an ACM certificate in us-east-1 that covers site_hostname"
}
