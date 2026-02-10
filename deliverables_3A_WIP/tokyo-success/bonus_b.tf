############################################
# Bonus B - ALB (Public) -> Target Group (Private EC2) + TLS + WAF + Monitoring
############################################

locals {
  # This is the full app domain name
  kandagawa_app_fqdn = "${var.app_subdomain}.${var.domain_name}"
}

############################################
# Security Group: ALB
############################################

resource "aws_security_group" "kandagawa_alb_sg01" {
  name        = "${var.project_name}-alb-sg01"
  description = "ALB security group"
  vpc_id      = aws_vpc.kandagawa_vpc01.id

  tags = {
    Name = "${var.project_name}-alb-sg01"
  }
}

# Allow HTTP from anywhere
resource "aws_vpc_security_group_ingress_rule" "kandagawa_alb_http_ingress" {
  security_group_id = aws_security_group.kandagawa_alb_sg01.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"

  tags = {
    Name = "${var.project_name}-alb-http-ingress"
  }
}

# Allow HTTPS from anywhere
resource "aws_vpc_security_group_ingress_rule" "kandagawa_alb_https_ingress" {
  security_group_id = aws_security_group.kandagawa_alb_sg01.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"

  tags = {
    Name = "${var.project_name}-alb-https-ingress"
  }
}

# Allow outbound to targets on port 80
resource "aws_vpc_security_group_egress_rule" "kandagawa_alb_egress_to_targets" {
  security_group_id            = aws_security_group.kandagawa_alb_sg01.id
  referenced_security_group_id = aws_security_group.kandagawa_ec2_sg01.id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"

  tags = {
    Name = "${var.project_name}-alb-egress-to-targets"
  }
}

############################################
# EC2 Security Group Rule: Allow ALB -> EC2
############################################

resource "aws_vpc_security_group_ingress_rule" "kandagawa_ec2_ingress_from_alb01" {
  security_group_id            = aws_security_group.kandagawa_ec2_sg01.id
  referenced_security_group_id = aws_security_group.kandagawa_alb_sg01.id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"

  tags = {
    Name = "${var.project_name}-ec2-ingress-from-alb"
  }
}

############################################
# Application Load Balancer
############################################

resource "aws_lb" "kandagawa_alb01" {
  name               = "${var.project_name}-alb01"
  load_balancer_type = "application"
  internal           = false

  security_groups = [aws_security_group.kandagawa_alb_sg01.id]
  subnets         = aws_subnet.kandagawa_public_subnets[*].id

#   # Enable access logs (configured below)
#   dynamic "access_logs" {
#     for_each = var.enable_alb_access_logs ? [1] : []
#     content {
#       bucket  = aws_s3_bucket.kandagawa_alb_logs_bucket01[0].bucket
#       prefix  = var.alb_access_logs_prefix
#       enabled = true
#     }
#   }

  tags = {
    Name = "${var.project_name}-alb01"
  }

#   depends_on = [aws_s3_bucket.kandagawa_alb_logs_bucket01]
}

############################################
# Target Group + Attachment
############################################

resource "aws_lb_target_group" "kandagawa_tg01" {
  name     = "${var.project_name}-tg01"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.kandagawa_vpc01.id

  health_check {
    enabled             = true
    interval            = 30
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    matcher             = "200-399"
  }

  tags = {
    Name = "${var.project_name}-tg01"
  }
}

resource "aws_lb_target_group_attachment" "kandagawa_tg_attach01" {
  target_group_arn = aws_lb_target_group.kandagawa_tg01.arn
  target_id        = aws_instance.kandagawa_ec201_private_bonus.id
  port             = 80
}

############################################
# ACM Certificate (TLS) for app.ackeeart.shop
############################################

resource "aws_acm_certificate" "kandagawa_acm_cert01" {
  domain_name       = local.kandagawa_app_fqdn
  provider = aws.us_east_1
  subject_alternative_names = [var.domain_name, local.kandagawa_app_fqdn]
  validation_method = "DNS" # i changed this temporarily from var.certificate_validation_method to "EMAIL" just to get up and running.

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.project_name}-acm-cert01"
  }
}

############################################
# ALB Listeners: HTTP -> HTTPS redirect, HTTPS -> TG
############################################

# HTTP listener redirects to HTTPS
resource "aws_lb_listener" "kandagawa_http_listener01" {
  load_balancer_arn = aws_lb.kandagawa_alb01.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# HTTPS listener forwards to target group, which i replaced for the one below cause ALB listeners require certificates in the same region as the ALB.and keep this here for reference.
# resource "aws_lb_listener" "kandagawa_https_listener01" {
#   load_balancer_arn = aws_lb.kandagawa_alb01.arn
#   port              = 443
#   protocol          = "HTTPS"
#   ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
#   certificate_arn   = aws_acm_certificate.kandagawa_acm_cert01.arn

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.kandagawa_tg01.arn
#   }

#   depends_on = [aws_acm_certificate_validation.kandagawa_acm_validation01_dns]
# }

resource "aws_lb_listener" "kandagawa_https_listener01" {
  load_balancer_arn = aws_lb.kandagawa_alb01.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# ############################################
# # WAFv2 Web ACL (Basic managed rules)
# ############################################

# resource "aws_wafv2_web_acl" "kandagawa_waf01" {
#   count = var.enable_waf ? 1 : 0

#   name  = "${var.project_name}-waf01"
#   scope = "REGIONAL"

#   default_action {
#     allow {}
#   }

#   visibility_config {
#     cloudwatch_metrics_enabled = true
#     metric_name                = "${var.project_name}-waf01"
#     sampled_requests_enabled   = true
#   }

#   rule {
#     name     = "AWSManagedRulesCommonRuleSet"
#     priority = 1

#     override_action {
#       none {}
#     }

#     statement {
#       managed_rule_group_statement {
#         name        = "AWSManagedRulesCommonRuleSet"
#         vendor_name = "AWS"
#       }
#     }

#     visibility_config {
#       cloudwatch_metrics_enabled = true
#       metric_name                = "${var.project_name}-waf-common"
#       sampled_requests_enabled   = true
#     }
#   }

#   tags = {
#     Name = "${var.project_name}-waf01"
#   }
# }

# # Attach WAF to ALB
# resource "aws_wafv2_web_acl_association" "kandagawa_waf_assoc01" {
#   count = var.enable_waf ? 1 : 0

#   resource_arn = aws_lb.kandagawa_alb01.arn
#   web_acl_arn  = aws_wafv2_web_acl.kandagawa_waf01[0].arn
# }

############################################
# CloudWatch Alarm: ALB 5xx -> SNS
############################################

resource "aws_cloudwatch_metric_alarm" "kandagawa_alb_5xx_alarm01" {
  alarm_name          = "${var.project_name}-alb-5xx-alarm01"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alb_5xx_evaluation_periods
  threshold           = var.alb_5xx_threshold
  period              = var.alb_5xx_period_seconds
  statistic           = "Sum"

  namespace   = "AWS/ApplicationELB"
  metric_name = "HTTPCode_ELB_5XX_Count"

  dimensions = {
    LoadBalancer = aws_lb.kandagawa_alb01.arn_suffix
  }

  alarm_actions = [aws_sns_topic.kandagawa_sns_topic01.arn]

  tags = {
    Name = "${var.project_name}-alb-5xx-alarm01"
  }
}

############################################
# CloudWatch Dashboard
############################################

resource "aws_cloudwatch_dashboard" "kandagawa_dashboard01" {
  dashboard_name = "${var.project_name}-dashboard01"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.kandagawa_alb01.arn_suffix],
            [".", "HTTPCode_ELB_5XX_Count", ".", "."]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "kandagawa ALB: Requests + 5XX"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", aws_lb.kandagawa_alb01.arn_suffix]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "kandagawa ALB: Target Response Time"
        }
      }
    ]
  })
}