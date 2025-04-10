# ACM Certificate
resource "aws_acm_certificate" "main" {
  domain_name       = "*.${var.route53_zone_name}"
  validation_method = "DNS"

  subject_alternative_names = [var.route53_zone_name]

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.prefix}-certificate"
  }
}

# DNS Validation Record
resource "aws_route53_record" "acm_validation" {
  for_each = {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.route53_zone_id
}

# Certificate Validation
resource "aws_acm_certificate_validation" "main" {
  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [for record in aws_route53_record.acm_validation : record.fqdn]
}

# DNS Record for the Application
resource "aws_route53_record" "app" {
  zone_id = var.route53_zone_id
  name    = "${var.prefix}.${var.route53_zone_name}"
  type    = "A"

  alias {
    name                   = data.aws_lb.ingress.dns_name
    zone_id               = data.aws_lb.ingress.zone_id
    evaluate_target_health = true
  }

  depends_on = [
    kubernetes_job.wait_for_alb_hostname
  ]
}

# Data source to fetch the ALB created by the Kubernetes ingress controller
data "aws_lb" "ingress" {
  tags = {
    "elbv2.k8s.aws/cluster" = "${var.prefix}-cluster"
    "ingress.k8s.aws/stack"   = "${kubernetes_namespace.foxglove.metadata[0].name}/site"
  }

  depends_on = [
    helm_release.primary_site,
    kubernetes_job.wait_for_alb_hostname
  ]
} 