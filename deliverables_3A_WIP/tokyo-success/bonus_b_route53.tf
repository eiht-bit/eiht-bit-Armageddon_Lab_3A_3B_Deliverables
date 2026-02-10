############################################
# Bonus B - Route53 (Hosted Zone + DNS records + ACM validation + ALIAS to ALB)
############################################

locals {

  # Explanation: E.T. needs a home planet—Route53 hosted zone is your DNS territory.
  kandagawa_zone_name = var.domain_name

  # Explanation: Use either Terraform-managed zone or a pre-existing zone ID (I choose my destiny).
  kandagawa_zone_id = var.manage_route53_in_terraform ? aws_route53_zone.kandagawa_zone01[0].zone_id : ""

  # Not repeating this line here, I don't need this shit twice in two separate TF files
}

############################################
# Hosted Zone for ackeeart.shop
############################################

resource "aws_route53_zone" "kandagawa_zone01" {
  count = var.manage_route53_in_terraform ? 1 : 0

  name = var.domain_name

  tags = {
    Name = "${var.project_name}-zone01"
  }
}

############################################
# ACM DNS Validation Records
############################################

# resource "aws_route53_record" "kandagawa_acm_validation_records01" {
#   for_each = var.certificate_validation_method == "DNS" ? {
#     for dvo in aws_acm_certificate.kandagawa_acm_cert01.domain_validation_options :
#     dvo.domain_name => {
#       name   = dvo.resource_record_name
#       type   = dvo.resource_record_type
#       record = dvo.resource_record_value
#     }
#   } : {}

#   zone_id = local.kandagawa_zone_id
#   name    = each.value.name
#   type    = each.value.type
#   ttl     = 60

#   records = [each.value.record]
# }

# # ACM certificate validation waits for DNS records
# resource "aws_acm_certificate_validation" "kandagawa_acm_validation01_dns" {
#   count = var.certificate_validation_method == "DNS" ? 1 : 0

#   certificate_arn = aws_acm_certificate.kandagawa_acm_cert01.arn

#   validation_record_fqdns = [
#     for r in aws_route53_record.kandagawa_acm_validation_records01 : r.fqdn
#   ]
# }

############################################
# ALIAS record: app.ackeeart.shop -> ALB
############################################

resource "aws_route53_record" "kandagawa_app_alias01" {
  zone_id = local.kandagawa_zone_id
  name    = local.kandagawa_app_fqdn
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.kandagawa_cf01.domain_name
    zone_id                = aws_cloudfront_distribution.kandagawa_cf01.hosted_zone_id
    evaluate_target_health = false
  }
}