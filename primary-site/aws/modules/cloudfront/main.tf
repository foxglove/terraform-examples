data "aws_cloudfront_cache_policy" "caching_disabled" {
  name = "Managed-CachingDisabled"
}

# Forwards every header, cookie and query string, including the `token` query parameter the
# query service authenticates with.
data "aws_cloudfront_origin_request_policy" "all_viewer" {
  name = "Managed-AllViewer"
}

resource "aws_cloudfront_distribution" "site" {
  enabled = true
  comment = "Foxglove primary site ${var.site_hostname}"
  aliases = [var.site_hostname]

  # Keeps viewers on TCP, where CloudFront uses BBR, instead of HTTP/3 over QUIC.
  http_version = "http2"

  origin {
    origin_id   = "load-balancer"
    domain_name = var.load_balancer_dns_name

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]

      # How long CloudFront waits for the first byte and between packets. 120 seconds is the
      # most allowed without a quota increase, so slower queries fail.
      origin_read_timeout = 120
    }
  }

  default_cache_behavior {
    target_origin_id       = "load-balancer"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods         = ["GET", "HEAD"]

    cache_policy_id = data.aws_cloudfront_cache_policy.caching_disabled.id

    # Forwarding the viewer's Host header lets the Ingress host rule match, and makes CloudFront
    # check the load balancer's certificate against site_hostname.
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewer.id
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}
