terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      # バージョンは環境に合わせて調整してください（例: 5.0以上など）
      version = ">= 5.0"
    }
  }
}

# ACM作成
resource "aws_acm_certificate" "virginia_cert" {

  domain_name       = var.domain
  validation_method = "DNS"

  tags = {
    created_by = var.owner
    Name       = "${var.project}-${var.env}-wildcard-sslcert"
    Project    = var.project
    Env        = var.env
  }

  lifecycle {
    create_before_destroy = true
  }
}

# DNS検証
resource "aws_route53_record" "route53_acm_dns_resolve" {
  for_each = {
    for dvo in aws_acm_certificate.virginia_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  allow_overwrite = true
  zone_id         = var.zone_id
  name            = each.value.name
  type            = each.value.type
  ttl             = 60
  records         = [each.value.record]
}
resource "aws_acm_certificate_validation" "cert_valid" {
  certificate_arn         = aws_acm_certificate.virginia_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.route53_acm_dns_resolve : record.fqdn]
}
