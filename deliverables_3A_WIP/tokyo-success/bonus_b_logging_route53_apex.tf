###########################################
# Bonus B - ALB Access Logs + Zone Apex ALIAS
###########################################

############################################
# Zone Apex (root domain) -> ALB
############################################

resource "aws_route53_record" "kandagawa_apex_alias01" {
  zone_id = local.kandagawa_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.kandagawa_cf01.domain_name
    zone_id                = aws_cloudfront_distribution.kandagawa_cf01.hosted_zone_id
    evaluate_target_health = false
  }
}

############################################
# S3 bucket for ALB access logs
############################################

resource "aws_s3_bucket" "kandagawa_alb_logs_bucket01" {
  count = var.enable_alb_access_logs ? 1 : 0

  bucket = "${var.project_name}-alb-logs-${data.aws_caller_identity.kandagawa_self01.account_id}"

  tags = {
    Name = "${var.project_name}-alb-logs-bucket01"
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "kandagawa_alb_logs_pab01" {
  count = var.enable_alb_access_logs ? 1 : 0

  bucket                  = aws_s3_bucket.kandagawa_alb_logs_bucket01[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Bucket ownership controls
resource "aws_s3_bucket_ownership_controls" "kandagawa_alb_logs_owner01" {
  count = var.enable_alb_access_logs ? 1 : 0

  bucket = aws_s3_bucket.kandagawa_alb_logs_bucket01[0].id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# Bucket policy for ALB access
resource "aws_s3_bucket_policy" "kandagawa_alb_logs_policy01" {
  count = var.enable_alb_access_logs ? 1 : 0

  bucket = aws_s3_bucket.kandagawa_alb_logs_bucket01[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyInsecureTransport"
        Effect = "Deny"
        Principal = "*"
        Action = "s3:*"
        Resource = [
          aws_s3_bucket.kandagawa_alb_logs_bucket01[0].arn,
          "${aws_s3_bucket.kandagawa_alb_logs_bucket01[0].arn}/*"
        ]
        Condition = {
          Bool = { "aws:SecureTransport" = "false" }
        }
      },
      {
        Sid    = "AllowELBPutObject"
        Effect = "Allow"
        Principal = {
          Service = "elasticloadbalancing.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.kandagawa_alb_logs_bucket01[0].arn}/${var.alb_access_logs_prefix}/AWSLogs/${data.aws_caller_identity.kandagawa_self01.account_id}/*"
      }
    ]
  })
}

############################################
# Enable ALB access logs (on the ALB resource)
############################################

# Explanation: Turn on access logs—Chewbacca wants receipts when something goes wrong.
# NOTE: This is a skeleton patch: students must merge this into aws_lb.chewbacca_alb01
# by adding/accessing the `access_logs` block. Terraform does not support "partial" blocks.
#
# Add this inside resource "aws_lb" "chewbacca_alb01" { ... } in bonus_b.tf:
#
# access_logs {
#   bucket  = aws_s3_bucket.chewbacca_alb_logs_bucket01[0].bucket
#   prefix  = var.alb_access_logs_prefix
#   enabled = var.enable_alb_access_logs
# }