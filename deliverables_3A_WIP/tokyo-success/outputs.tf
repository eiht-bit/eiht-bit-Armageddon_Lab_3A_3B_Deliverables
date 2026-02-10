# Explanation: Outputs are your mission report—what got built and where to find it.
output "kandagawa_vpc_id" {
  value = aws_vpc.kandagawa_vpc01.id
}

output "kandagawa_public_subnet_ids" {
  value = aws_subnet.kandagawa_public_subnets[*].id
}

output "kandagawa_private_subnet_ids" {
  value = aws_subnet.kandagawa_private_subnets[*].id
}

# output "kandagawa_ec2_instance_id" {
#   value = aws_instance.kandagawa_ec201.id
# }

# output "kandagawa_ec2_public_ip" {
#   value = aws_instance.kandagawa_ec201.public_ip
# }

output "kandagawa_rds_endpoint" {
  value = aws_db_instance.kandagawa_rds01.address
}

output "kandagawa_sns_topic_arn" {
  value = aws_sns_topic.kandagawa_sns_topic01.arn
}

output "kandagawa_log_group_name" {
  value = aws_cloudwatch_log_group.kandagawa_log_group01.name
}

############################################
# Bonus-A outputs
############################################

# Explanation: These outputs prove kandagawa built private hyperspace lanes (endpoints) instead of public chaos.
output "kandagawa_vpce_ssm_id" {
  description = "VPC Endpoint ID for SSM"
  value       = aws_vpc_endpoint.kandagawa_vpce_ssm01.id
}

output "kandagawa_vpce_ec2messages_id" {
  description = "VPC Endpoint ID for EC2 Messages"
  value       = aws_vpc_endpoint.kandagawa_vpce_ec2messages01.id
}

output "kandagawa_vpce_ssmmessages_id" {
  description = "VPC Endpoint ID for SSM Messages"
  value       = aws_vpc_endpoint.kandagawa_vpce_ssmmessages01.id
}

output "kandagawa_vpce_logs_id" {
  description = "VPC Endpoint ID for CloudWatch Logs"
  value       = aws_vpc_endpoint.kandagawa_vpce_logs01.id
}

output "kandagawa_vpce_secrets_id" {
  description = "VPC Endpoint ID for Secrets Manager"
  value       = aws_vpc_endpoint.kandagawa_vpce_secrets01.id
}

output "kandagawa_vpce_kms_id" {
  description = "VPC Endpoint ID for KMS"
  value       = aws_vpc_endpoint.kandagawa_vpce_kms01.id
}

output "kandagawa_vpce_s3_id" {
  description = "VPC Endpoint ID for S3 (Gateway)"
  value       = aws_vpc_endpoint.kandagawa_vpce_s3_gw01.id
}

output "kandagawa_private_ec2_instance_id" {
  description = "Private EC2 Instance ID (Bonus A)"
  value       = aws_instance.kandagawa_ec201_private_bonus.id
}

output "kandagawa_vpce_security_group_id" {
  description = "Security Group ID for VPC Endpoints"
  value       = aws_security_group.kandagawa_vpce_sg01.id
}

############################################
# Bonus-B Outputs
############################################

output "kandagawa_alb_dns_name" {
  description = "ALB DNS name (use this to test BEFORE domain setup)"
  value       = aws_lb.kandagawa_alb01.dns_name
}

output "kandagawa_app_fqdn" {
  description = "Your custom domain app URL"
  value       = "https://${var.app_subdomain}.${var.domain_name}"
}

output "kandagawa_target_group_arn" {
  value = aws_lb_target_group.kandagawa_tg01.arn
}

output "kandagawa_acm_cert_arn" {
  value = aws_acm_certificate.kandagawa_acm_cert01.arn
}

# output "kandagawa_waf_arn" {
#   value = var.enable_waf ? aws_wafv2_web_acl.kandagawa_waf01[0].arn : null
# }

output "kandagawa_dashboard_name" {
  value = aws_cloudwatch_dashboard.kandagawa_dashboard01.dashboard_name
}

output "kandagawa_apex_url" {
  description = "Root domain URL"
  value       = "https://${var.domain_name}"
}

output "kandagawa_alb_logs_bucket_name" {
  value = var.enable_alb_access_logs ? aws_s3_bucket.kandagawa_alb_logs_bucket01[0].bucket : null
}

# output "kandagawa_waf_log_group_name" {
#   value = var.enable_waf && var.waf_log_destination == "cloudwatch" ? aws_cloudwatch_log_group.kandagawa_waf_log_group01[0].name : null
# }

output "kandagawa_route53_zone_id" {
  description = "Route53 Hosted Zone ID - I WILL USE THESE NAMESERVERS IN GODADDY"
  value       = local.kandagawa_zone_id
}

output "kandagawa_route53_nameservers" {
  description = "i need to remember to COPY THESE to GoDaddy nameserver settings"
  value       = var.manage_route53_in_terraform ? aws_route53_zone.kandagawa_zone01[0].name_servers : null
}

output "kandagawa_app_url_https" {
  value = "https://${var.app_subdomain}.${var.domain_name}"
}

output "kandagawa_cf_waf_arn" {
  value = aws_wafv2_web_acl.kandagawa_cf_waf01.arn
}

output "kandagawa_cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.kandagawa_cf01.id
}

output "kandagawa_cloudfront_domain_name" {
  value = aws_cloudfront_distribution.kandagawa_cf01.domain_name
}

############################################
# Lab 3A
############################################

output "kandagawa_vpc_cidr" {
  description = "kandagawa VPC CIDR block"
  value       = aws_vpc.kandagawa_vpc01.cidr_block
}

output "kandagawa_tgw_id" {
  description = "kandagawa Transit Gateway ID"
  value       = aws_ec2_transit_gateway.kandagawa_tgw01.id
}

output "kandagawa_tgw_peering_attachment_id" {
  description = "kandagawa TGW peering attachment ID"
  value       = aws_ec2_transit_gateway_peering_attachment.kandagawa_to_liberdade_peer01.id
}