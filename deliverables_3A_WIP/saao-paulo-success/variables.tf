variable "project_name" {
  description = "project name is liberdade for São Paulo"
  type        = string
  default     = "liberdade"
}

variable "aws_region" {
  description = "AWS Region sao."
  type        = string
  default     = "sa-east-1"
}

variable "vpc_cidr" {
  description = "VPC CIDR sao."
  type        = string
  default     = "10.20.0.0/16" # TODO: student supplies (done)
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs sao."
  type        = list(string)
  default     = ["10.20.1.0/24", "10.20.2.0/24"] # TODO: student supplies (done)
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDRs sao."
  type        = list(string)
  default     = ["10.20.11.0/24", "10.20.12.0/24"] # TODO: student supplies (done)
}

variable "azs" {
  description = "Availability Zones list (match count with subnets)."
  type        = list(string)
  default     = ["sa-east-1a", "sa-east-1b"] # TODO: student supplies (done)
}

variable "ec2_ami_id" {
  description = "AMI ID for the EC2 app host."
  type        = string
  default     = "ami-0f85876b1aff99dde" # TODO (done)
}

variable "ec2_instance_type" {
  description = "EC2 instance size for the app."
  type        = string
  default     = "t3.micro"
}

variable "sns_email_endpoint" {
  description = "Email for SNS subscription (PagerDuty simulation)."
  type        = string
  default     = "vincemclean11@yahoo.com" # TODO: student supplies (done)
}

############################################
# Bonus B Variables
############################################

variable "domain_name" {
  description = "My registered domain (managed in GoDaddy, DNS in Route53)"
  type        = string
  default     = "ackeeart.shop"
}

variable "app_subdomain" {
  description = "App hostname prefix (e.g., app.ackeeart.shop)"
  type        = string
  default     = "app"
}

variable "certificate_validation_method" {
  description = "ACM validation method. Students can do DNS (Route53) or EMAIL."
  type        = string
  default     = "DNS"
}

variable "enable_waf" {
  description = "Toggle WAF creation."
  type        = bool
  default     = true
}

variable "alb_5xx_threshold" {
  description = "Alarm threshold for ALB 5xx count."
  type        = number
  default     = 10
}

variable "alb_5xx_period_seconds" {
  description = "CloudWatch alarm period."
  type        = number
  default     = 300
}

variable "alb_5xx_evaluation_periods" {
  description = "Evaluation periods for alarm."
  type        = number
  default     = 1
}

variable "enable_alb_access_logs" {
  description = "Enable ALB access logging to S3."
  type        = bool
  default     = true
}

variable "alb_access_logs_prefix" {
  description = "S3 prefix for ALB access logs."
  type        = string
  default     = "alb-access-logs"
}

variable "manage_route53_in_terraform" {
  description = "If true, create/manage Route53 hosted zone in Terraform."
  type        = bool
  default     = false
}

variable "waf_log_destination" {
  description = "Choose ONE destination per WebACL: cloudwatch | s3 | firehose"
  type        = string
  default     = "cloudwatch"
}

variable "waf_log_retention_days" {
  description = "Retention for WAF CloudWatch log group."
  type        = number
  default     = 14
}

variable "route53_hosted_zone_id" {
  description = "If manage_route53_in_terraform=false, provide existing Hosted Zone ID for domain."
  type        = string
  default     = ""
}

############################################
# Lab 3A
############################################

# Tokyo CIDR (for routing)
variable "tokyo_vpc_cidr" {
  description = "Tokyo VPC CIDR block from Tokyo outputs"
  type        = string
  default     = "10.10.0.0/16"  # will be overridden by remote state
}

# Tokyo TGW ID (will come from remote state)
variable "tokyo_tgw_id" {
  description = "Tokyo Transit Gateway ID"
  type        = string
  default     = ""  # Will be populated from remote state
}

# Tokyo RDS endpoint (will come from remote state)
variable "tokyo_rds_endpoint" {
  description = "Tokyo RDS endpoint"
  type        = string
  default     = ""  # Will be populated from remote state, who'd have thought!
}

