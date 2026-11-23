output "domain_name" {
  value       = aws_cloudfront_distribution.site.domain_name
  description = "Domain name of the CloudFront distribution"
}

output "hosted_zone_id" {
  value       = aws_cloudfront_distribution.site.hosted_zone_id
  description = "Route 53 hosted zone ID for alias records that point at the distribution"
}
