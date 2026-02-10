############################################
# Bonus A - Data + Locals
############################################

# Explanation: liberdade wants to know "who am I in this world?" so ARNs can be scoped properly.
data "aws_caller_identity" "liberdade_self01" {}

# Explanation: Region matters—cutures shifts per sector.
data "aws_region" "liberdade_region01" {}

locals {
  # TODO: Students should lock this down after apply using the real secret ARN from outputs/state
  liberdade_secret_arn_guess = "arn:aws:secretsmanager:${data.aws_region.liberdade_region01.name}:${data.aws_caller_identity.liberdade_self01.account_id}:secret:${local.name_prefix}/rds/mysql*"
}

##############################################
# Move EC2 into PRIVATE subnet (no public IP)
##############################################

# Explanation: liberdade hates exposure—private subnets keep your compute off the public eyes.
resource "aws_instance" "liberdade_ec201_private_bonus" {
  ami                    = var.ec2_ami_id
  instance_type          = var.ec2_instance_type
  subnet_id              = aws_subnet.liberdade_private_subnets[0].id
  vpc_security_group_ids = [aws_security_group.liberdade_ec2_sg01.id]
  iam_instance_profile   = aws_iam_instance_profile.liberdade_instance_profile01.name

  user_data = file("${path.module}/user_data.sh")

  tags = {
    Name = "${local.name_prefix}-ec201-private"
  }
}

############################################
# Security Group for VPC Interface Endpoints
############################################

# Explanation: Even endpoints need guards—liberdade posts muscle at every airlock.
resource "aws_security_group" "liberdade_vpce_sg01" {
  name        = "${local.name_prefix}-vpce-sg01"
  description = "SG for VPC Interface Endpoints"
  vpc_id      = aws_vpc.liberdade_vpc01.id

  tags = {
    Name = "${local.name_prefix}-vpce-sg01"
  }
}

# Allow HTTPS (443) inbound from EC2 security group
resource "aws_vpc_security_group_ingress_rule" "liberdade_vpce_ingress_from_ec2" {
  security_group_id            = aws_security_group.liberdade_vpce_sg01.id
  referenced_security_group_id = aws_security_group.liberdade_ec2_sg01.id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"

  tags = {
    Name = "${local.name_prefix}-vpce-ingress-from-ec2"
  }
}

# Allow all outbound (standard practice for endpoint SGs)
resource "aws_vpc_security_group_egress_rule" "liberdade_vpce_egress" {
  security_group_id = aws_security_group.liberdade_vpce_sg01.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"

  tags = {
    Name = "${local.name_prefix}-vpce-egress"
  }
}

############################################
# VPC Endpoint - S3 (Gateway)
############################################

# Explanation: S3 is the supply depot—without this, your private world starves (updates, artifacts, logs).
resource "aws_vpc_endpoint" "liberdade_vpce_s3_gw01" {
  vpc_id            = aws_vpc.liberdade_vpc01.id
  service_name      = "com.amazonaws.${data.aws_region.liberdade_region01.name}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [
    aws_route_table.liberdade_private_rt01.id
  ]

  tags = {
    Name = "${local.name_prefix}-vpce-s3-gw01"
  }
}

############################################
# VPC Endpoints - SSM (Interface)
############################################

# Explanation: SSM is your Force choke—remote control without SSH, and nobody sees your keys.
resource "aws_vpc_endpoint" "liberdade_vpce_ssm01" {
  vpc_id              = aws_vpc.liberdade_vpc01.id
  service_name        = "com.amazonaws.${data.aws_region.liberdade_region01.name}.ssm"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids         = aws_subnet.liberdade_private_subnets[*].id
  security_group_ids = [aws_security_group.liberdade_vpce_sg01.id]

  tags = {
    Name = "${local.name_prefix}-vpce-ssm01"
  }
}

# Explanation: ec2messages is the whatsapp messenger—SSM sessions won't work without it.
resource "aws_vpc_endpoint" "liberdade_vpce_ec2messages01" {
  vpc_id              = aws_vpc.liberdade_vpc01.id
  service_name        = "com.amazonaws.${data.aws_region.liberdade_region01.name}.ec2messages"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids         = aws_subnet.liberdade_private_subnets[*].id
  security_group_ids = [aws_security_group.liberdade_vpce_sg01.id]

  tags = {
    Name = "${local.name_prefix}-vpce-ec2messages01"
  }
}

# Explanation: ssmmessages is the channel live—Session Manager needs it to talk back.
resource "aws_vpc_endpoint" "liberdade_vpce_ssmmessages01" {
  vpc_id              = aws_vpc.liberdade_vpc01.id
  service_name        = "com.amazonaws.${data.aws_region.liberdade_region01.name}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids         = aws_subnet.liberdade_private_subnets[*].id
  security_group_ids = [aws_security_group.liberdade_vpce_sg01.id]

  tags = {
    Name = "${local.name_prefix}-vpce-ssmmessages01"
  }
}

############################################
# VPC Endpoint - CloudWatch Logs (Interface)
############################################

# Explanation: CloudWatch Logs is the ships's black box—liberdade wants crash data, always.
resource "aws_vpc_endpoint" "liberdade_vpce_logs01" {
  vpc_id              = aws_vpc.liberdade_vpc01.id
  service_name        = "com.amazonaws.${data.aws_region.liberdade_region01.name}.logs"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids         = aws_subnet.liberdade_private_subnets[*].id
  security_group_ids = [aws_security_group.liberdade_vpce_sg01.id]

  tags = {
    Name = "${local.name_prefix}-vpce-logs01"
  }
}

############################################
# VPC Endpoint - Secrets Manager (Interface)
############################################

# Explanation: Secrets Manager is the locked vault—liberdade doesn't put passwords on sticky notes.
resource "aws_vpc_endpoint" "liberdade_vpce_secrets01" {
  vpc_id              = aws_vpc.liberdade_vpc01.id
  service_name        = "com.amazonaws.${data.aws_region.liberdade_region01.name}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids         = aws_subnet.liberdade_private_subnets[*].id
  security_group_ids = [aws_security_group.liberdade_vpce_sg01.id]

  tags = {
    Name = "${local.name_prefix}-vpce-secrets01"
  }
}

############################################
# Optional: VPC Endpoint - KMS (Interface)
############################################

# Explanation: KMS is the encryption kyber crystal—liberdade prefers locked doors AND locked safes.
resource "aws_vpc_endpoint" "liberdade_vpce_kms01" {
  vpc_id              = aws_vpc.liberdade_vpc01.id
  service_name        = "com.amazonaws.${data.aws_region.liberdade_region01.name}.kms"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids         = aws_subnet.liberdade_private_subnets[*].id
  security_group_ids = [aws_security_group.liberdade_vpce_sg01.id]

  tags = {
    Name = "${local.name_prefix}-vpce-kms01"
  }
}

############################################
# Least-Privilege IAM (BONUS A)
############################################

# Explanation: liberdade doesn't hand out the Falcon keys—this policy scopes reads to your lab paths only.
resource "aws_iam_policy" "liberdade_leastpriv_read_params01" {
  name        = "${local.name_prefix}-lp-ssm-read01"
  description = "Least-privilege read for SSM Parameter Store under /lab/db/*"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadLabDbParams"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = [
          "arn:aws:ssm:${data.aws_region.liberdade_region01.name}:${data.aws_caller_identity.liberdade_self01.account_id}:parameter/lab/db/*"
        ]
      }
    ]
  })

  tags = {
    Name = "${local.name_prefix}-lp-ssm-read01"
  }
}

# Explanation: liberdade only opens *this* vault—GetSecretValue for only your secret (not the whole planet).
resource "aws_iam_policy" "liberdade_leastpriv_read_secret01" {
  name        = "${local.name_prefix}-lp-secrets-read01"
  description = "Least-privilege read for the lab DB secret"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadOnlyLabSecret"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = local.liberdade_secret_arn_guess
      }
    ]
  })

  tags = {
    Name = "${local.name_prefix}-lp-secrets-read01"
  }
}

# Explanation: When the Falcon logs scream, this lets liberdade ship logs to CloudWatch without giving away the Death Star plans.
resource "aws_iam_policy" "liberdade_leastpriv_cwlogs01" {
  name        = "${local.name_prefix}-lp-cwlogs01"
  description = "Least-privilege CloudWatch Logs write for the app log group"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "WriteLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = [
          "${aws_cloudwatch_log_group.liberdade_log_group01.arn}:*"
        ]
      }
    ]
  })

  tags = {
    Name = "${local.name_prefix}-lp-cwlogs01"
  }
}

# Explanation: Attach the scoped policies—liberdade loves power, but only the safe kind.
resource "aws_iam_role_policy_attachment" "liberdade_attach_lp_params01" {
  role       = aws_iam_role.liberdade_ec2_role01.name
  policy_arn = aws_iam_policy.liberdade_leastpriv_read_params01.arn
}

resource "aws_iam_role_policy_attachment" "liberdade_attach_lp_secret01" {
  role       = aws_iam_role.liberdade_ec2_role01.name
  policy_arn = aws_iam_policy.liberdade_leastpriv_read_secret01.arn
}

resource "aws_iam_role_policy_attachment" "liberdade_attach_lp_cwlogs01" {
  role       = aws_iam_role.liberdade_ec2_role01.name
  policy_arn = aws_iam_policy.liberdade_leastpriv_cwlogs01.arn
}

# │ Warning: Deprecated attribute
# │ 
# │   on bonus_a.tf line 13, in locals:
# │   13:   liberdade_secret_arn_guess = "arn:aws:secretsmanager:${data.aws_region.liberdade_region01.name}:${data.aws_caller_identity.liberdade_self01.account_id}:secret:${local.name_prefix}/rds/mysql*"
# │ 
# │ The attribute "name" is deprecated. Refer to the provider documentation for details.
# │
# │ (and 8 more similar warnings elsewhere)


