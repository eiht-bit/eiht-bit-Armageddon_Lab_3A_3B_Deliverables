# Explanation: Outputs are your mission report—what got built and where to find it.
output "liberdade_vpc_id" {
  value = aws_vpc.liberdade_vpc01.id
}

output "liberdade_public_subnet_ids" {
  value = aws_subnet.liberdade_public_subnets[*].id
}

output "liberdade_private_subnet_ids" {
  value = aws_subnet.liberdade_private_subnets[*].id
}

# output "liberdade_ec2_instance_id" {
#   value = aws_instance.liberdade_ec201.id
# }

# output "liberdade_ec2_public_ip" {
#   value = aws_instance.liberdade_ec201.public_ip
# }

# sao paulo does not have rds. duh!
# output "liberdade_rds_endpoint" {
#   value = aws_db_instance.liberdade_rds01.address
# }

output "liberdade_sns_topic_arn" {
  value = aws_sns_topic.liberdade_sns_topic01.arn
}

output "liberdade_log_group_name" {
  value = aws_cloudwatch_log_group.liberdade_log_group01.name
}

############################################
# Bonus-A outputs
############################################

# Explanation: These outputs prove liberdade built private hyperspace lanes (endpoints) instead of public chaos.
output "liberdade_vpce_ssm_id" {
  description = "VPC Endpoint ID for SSM"
  value       = aws_vpc_endpoint.liberdade_vpce_ssm01.id
}

output "liberdade_vpce_ec2messages_id" {
  description = "VPC Endpoint ID for EC2 Messages"
  value       = aws_vpc_endpoint.liberdade_vpce_ec2messages01.id
}

output "liberdade_vpce_ssmmessages_id" {
  description = "VPC Endpoint ID for SSM Messages"
  value       = aws_vpc_endpoint.liberdade_vpce_ssmmessages01.id
}

output "liberdade_vpce_logs_id" {
  description = "VPC Endpoint ID for CloudWatch Logs"
  value       = aws_vpc_endpoint.liberdade_vpce_logs01.id
}

output "liberdade_vpce_secrets_id" {
  description = "VPC Endpoint ID for Secrets Manager"
  value       = aws_vpc_endpoint.liberdade_vpce_secrets01.id
}

output "liberdade_vpce_kms_id" {
  description = "VPC Endpoint ID for KMS"
  value       = aws_vpc_endpoint.liberdade_vpce_kms01.id
}

output "liberdade_vpce_s3_id" {
  description = "VPC Endpoint ID for S3 (Gateway)"
  value       = aws_vpc_endpoint.liberdade_vpce_s3_gw01.id
}

output "liberdade_private_ec2_instance_id" {
  description = "Private EC2 Instance ID (Bonus A)"
  value       = aws_instance.liberdade_ec201_private_bonus.id
}

output "liberdade_vpce_security_group_id" {
  description = "Security Group ID for VPC Endpoints"
  value       = aws_security_group.liberdade_vpce_sg01.id
}

############################################
# Bonus-B Outputs
############################################

output "liberdade_alb_dns_name" {
  description = "ALB DNS name (use this to test BEFORE domain setup)"
  value       = aws_lb.liberdade_alb01.dns_name
}

output "liberdade_app_fqdn" {
  description = "Your custom domain app URL"
  value       = "https://${var.app_subdomain}.${var.domain_name}"
}

output "liberdade_target_group_arn" {
  value = aws_lb_target_group.liberdade_tg01.arn
}

# output "liberdade_acm_cert_arn" {
#   value = aws_acm_certificate.liberdade_acm_cert01.arn
# }

# output "liberdade_waf_arn" {
#   value = var.enable_waf ? aws_wafv2_web_acl.liberdade_waf01[0].arn : null
# }

output "liberdade_dashboard_name" {
  value = aws_cloudwatch_dashboard.liberdade_dashboard01.dashboard_name
}

output "liberdade_apex_url" {
  description = "Root domain URL"
  value       = "https://${var.domain_name}"
}

output "liberdade_alb_logs_bucket_name" {
  value = var.enable_alb_access_logs ? aws_s3_bucket.liberdade_alb_logs_bucket01[0].bucket : null
}

# output "liberdade_waf_log_group_name" {
#   value = var.enable_waf && var.waf_log_destination == "cloudwatch" ? aws_cloudwatch_log_group.liberdade_waf_log_group01[0].name : null
# }

output "liberdade_route53_zone_id" {
  description = "Route53 Hosted Zone ID - I WILL USE THESE NAMESERVERS IN GODADDY"
  value       = local.liberdade_zone_id
}

output "liberdade_route53_nameservers" {
  description = "i need to remember to COPY THESE to GoDaddy nameserver settings"
  value       = var.manage_route53_in_terraform ? aws_route53_zone.liberdade_zone01[0].name_servers : null
}

output "liberdade_app_url_https" {
  value = "https://${var.app_subdomain}.${var.domain_name}"
}

output "liberdade_cf_waf_arn" {
  value = aws_wafv2_web_acl.liberdade_cf_waf01.arn
}

output "liberdade_cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.liberdade_cf01.id
}

output "liberdade_cloudfront_domain_name" {
  value = aws_cloudfront_distribution.liberdade_cf01.domain_name
}

############################################
# lab 3 outputs
############################################

output "liberdade_tgw_id" {
  description = "São Paulo Transit Gateway ID, lets git it!"
  value       = aws_ec2_transit_gateway.liberdade_tgw01.id
}