# Explanation: CloudFront is the only public doorway — liberdade stands behind it with private infrastructure.
resource "aws_cloudfront_distribution" "liberdade_cf01" {
  enabled         = true
  is_ipv6_enabled = true
  comment         = "${var.project_name}-cf01"
  provider        = aws.us_east_1

  origin {
    origin_id   = "${var.project_name}-alb-origin01"
    domain_name = aws_lb.liberdade_alb01.dns_name

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }

    # Explanation: CloudFront whispers the secret — the ALB only trusts this.
    custom_header {
      name  = "liberdade-is-liberdade"
      value = random_password.liberdade_origin_header_value01.result
    }
  }

  default_cache_behavior {
    target_origin_id       = "${var.project_name}-alb-origin01"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods  = ["GET", "HEAD"]

    forwarded_values {
      query_string = true
      headers      = ["*"]
      cookies {
        forward = "all"
      }
    }
  }

  # Explanation: Attach WAF at the edge — WAF now lives on CloudFront.
  web_acl_id = aws_wafv2_web_acl.liberdade_cf_waf01.arn

  # aliases = [
  #   var.domain_name,
  #   "${var.app_subdomain}.${var.domain_name}"
  # ]

  viewer_certificate {
    acm_certificate_arn = local.tokyo_acm_cert_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}