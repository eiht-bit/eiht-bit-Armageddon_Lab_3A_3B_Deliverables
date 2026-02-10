############################################
# Locals (naming convention: kandagawa-*)
############################################
locals {
  name_prefix = var.project_name
}

############################################
# VPC + Internet Gateway
############################################

# Explanation: kandagawa is the Goal.
resource "aws_vpc" "kandagawa_vpc01" {
  cidr_block           = var.vpc_cidr
  instance_tenancy = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${local.name_prefix}-vpc01"
  }
}

# Explanation: The Flood Gates Have Opened
resource "aws_internet_gateway" "kandagawa_igw01" {
  vpc_id = aws_vpc.kandagawa_vpc01.id

  tags = {
    Name = "${local.name_prefix}-igw01"
  }
}

############################################
# Subnets (Public + Private)
############################################

# Explanation: Public subnets are Port of Miami.
resource "aws_subnet" "kandagawa_public_subnets" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.kandagawa_vpc01.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.name_prefix}-public-subnet0${count.index + 1}"
  }
}

# Explanation: Private subnets are Star Island.
resource "aws_subnet" "kandagawa_private_subnets" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.kandagawa_vpc01.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index]

  tags = {
    Name = "${local.name_prefix}-private-subnet0${count.index + 1}"
  }
}

############################################
# NAT Gateway + EIP
############################################

# Explanation: kandagawa wants the private base to call home—EIP gives the NAT a stable “addy.”
resource "aws_eip" "kandagawa_nat_eip01" {
  domain = "vpc"

  tags = {
    Name = "${local.name_prefix}-nat-eip01"
  }
}

# Explanation: NAT is kandagawa’s smuggler tunnel—private subnets can reach out without being seen.
resource "aws_nat_gateway" "kandagawa_nat01" {
  allocation_id = aws_eip.kandagawa_nat_eip01.id
  subnet_id     = aws_subnet.kandagawa_public_subnets[0].id # NAT in a public subnet

  tags = {
    Name = "${local.name_prefix}-nat01"
  }

  depends_on = [aws_internet_gateway.kandagawa_igw01]
}

############################################
# Routing (Public + Private Route Tables)
############################################

# Explanation: Public route table = “open lanes” to the life via IGW.
resource "aws_route_table" "kandagawa_public_rt01" {
  vpc_id = aws_vpc.kandagawa_vpc01.id

  tags = {
    Name = "${local.name_prefix}-public-rt01"
  }
}

# Explanation: This route is the yacht—0.0.0.0/0 goes out the IGW.
resource "aws_route" "kandagawa_public_default_route" {
  route_table_id         = aws_route_table.kandagawa_public_rt01.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.kandagawa_igw01.id
}

# Explanation: Attach public subnets to the “scene.”
resource "aws_route_table_association" "kandagawa_public_rta" {
  count          = length(aws_subnet.kandagawa_public_subnets)
  subnet_id      = aws_subnet.kandagawa_public_subnets[count.index].id
  route_table_id = aws_route_table.kandagawa_public_rt01.id
}

# Explanation: Private route table = “stay hidden, but still in plain site.”
resource "aws_route_table" "kandagawa_private_rt01" {
  vpc_id = aws_vpc.kandagawa_vpc01.id

  tags = {
    Name = "${local.name_prefix}-private-rt01"
  }
}

# Explanation: Private subnets route outbound internet via NAT (kandagawa-approved stealth).
resource "aws_route" "kandagawa_private_default_route" {
  route_table_id         = aws_route_table.kandagawa_private_rt01.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.kandagawa_nat01.id
}

# Explanation: Attach private subnets to the “sneaky links.”
resource "aws_route_table_association" "kandagawa_private_rta" {
  count          = length(aws_subnet.kandagawa_private_subnets)
  subnet_id      = aws_subnet.kandagawa_private_subnets[count.index].id
  route_table_id = aws_route_table.kandagawa_private_rt01.id
}

############################################
# Security Groups (EC2 + RDS)
############################################

# Explanation: EC2 SG is kandagawa’s muscle—only let in what you mean to.
resource "aws_security_group" "kandagawa_ec2_sg01" {
  name        = "${local.name_prefix}-ec2-sg01"
  description = "EC2 app security group"
  vpc_id      = aws_vpc.kandagawa_vpc01.id

  tags = {
    Name = "${local.name_prefix}-ec2-sg01"
  }
}

resource "aws_vpc_security_group_ingress_rule" "kandagawa_ec2_http_ingress" {
  security_group_id = aws_security_group.kandagawa_ec2_sg01.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
  tags = {
    Name = "${local.name_prefix}-ec2-http-ingress"
  }

}

resource "aws_vpc_security_group_ingress_rule" "kandagawa_ec2_ssh_ingress" {
  security_group_id = aws_security_group.kandagawa_ec2_sg01.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
  tags = {
    Name = "${local.name_prefix}-ec2-ssh-ingress"
  }
}

resource "aws_vpc_security_group_egress_rule" "kandagawa_ec2_egress" {
  security_group_id = aws_security_group.kandagawa_ec2_sg01.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
    tags = {
      Name = "${local.name_prefix}-ec2-egress"
  }
}


# Explanation: RDS SG is the safe—only the app server gets a keycard.
resource "aws_security_group" "kandagawa_rds_sg01" {
  name        = "${local.name_prefix}-rds-sg01"
  description = "RDS security group"
  vpc_id      = aws_vpc.kandagawa_vpc01.id

  tags = {
    Name = "${local.name_prefix}-rds-sg01"
  }
}

resource "aws_vpc_security_group_ingress_rule" "kandagawa_rds_ingress" {
  security_group_id = aws_security_group.kandagawa_rds_sg01.id
  referenced_security_group_id = aws_security_group.kandagawa_ec2_sg01.id
  from_port         = 3306
  ip_protocol       = "tcp"
  to_port           = 3306
    tags = {
      Name = "${local.name_prefix}-rds-ingress"
  }
}

resource "aws_vpc_security_group_ingress_rule" "kandagawa_rds_ingress_from_saopaulo" {
  security_group_id = aws_security_group.kandagawa_rds_sg01.id
  cidr_ipv4         = var.saopaulo_vpc_cidr  # São Paulo VPC CIDR
  from_port         = 3306
  to_port           = 3306
  ip_protocol       = "tcp"

  tags = {
    Name = "${local.name_prefix}-rds-ingress-from-saopaulo"
  }
}
resource "aws_vpc_security_group_egress_rule" "kandagawa_rds_egress" {
  security_group_id = aws_security_group.kandagawa_rds_sg01.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
    tags = {
      Name = "${local.name_prefix}-rds-egress"
  }
}


###########################################
# RDS Subnet Group
###########################################

# Explanation: RDS hides in private subnets like wrinkles on white tees.
resource "aws_db_subnet_group" "kandagawa_rds_subnet_group01" {
  name       = "${local.name_prefix}-rds-subnet-group01"
  subnet_ids = aws_subnet.kandagawa_private_subnets[*].id

  tags = {
    Name = "${local.name_prefix}-rds-subnet-group01"
  }
}

############################################
# RDS Instance (MySQL)
############################################

# Explanation: This is the elephant of state—your relational data lives here, not on the EC2.
resource "aws_db_instance" "kandagawa_rds01" {
  identifier             = "${local.name_prefix}-rds01"
  engine                 = var.db_engine
  instance_class         = var.db_instance_class
  allocated_storage      = 20
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.kandagawa_rds_subnet_group01.name
  vpc_security_group_ids = [aws_security_group.kandagawa_rds_sg01.id]

  publicly_accessible    = false
  skip_final_snapshot    = true

  # TODO: student sets multi_az / backups / monitoring as stretch goals (done)
  multi_az                     = false
  backup_retention_period      = 1
  backup_window                = "03:00-04:00"
  maintenance_window           = "sun:04:00-sun:05:00"
  monitoring_interval          = 0
  enabled_cloudwatch_logs_exports = ["error"]

  tags = {
    Name = "${local.name_prefix}-rds01"
  }
}

############################################
# IAM Role + Instance Profile for EC2
############################################

# Explanation: kandagawa refuses to carry static keys—this role lets EC2 assume permissions safely.
resource "aws_iam_role" "kandagawa_ec2_role01" {
  name = "${local.name_prefix}-ec2-role01"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Name = "${local.name_prefix}-ec2-role01"
  }
}

resource "aws_iam_role_policy" "kandagawa_lab1a_policy" {
  name = "${local.name_prefix}-lab1a-secrets-policy"
  role = aws_iam_role.kandagawa_ec2_role01.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid      = "ReadSpecificSecret"
      Effect   = "Allow"
      Action   = ["secretsmanager:GetSecretValue"]
      Resource = "arn:aws:secretsmanager:${var.aws_region}:*:secret:lab/rds/mysqli*"
    }]
  })
}

resource "aws_iam_role_policy" "kandagawa_lab1b_policy" {
  name = "${local.name_prefix}-lab1b-params-logs-policy"
  role = aws_iam_role.kandagawa_ec2_role01.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ReadParameterStore"
        Effect   = "Allow"
        Action   = ["ssm:GetParameter"]
        Resource = "arn:aws:ssm:${var.aws_region}:*:parameter/lab/db/*"
      },
      {
        Sid    = "WriteCloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:*:log-group:/aws/ec2/lab-rds-app:*"
      }
    ]
  })
}

# Who would have thought that the AWS console creates an iam user behind the scenes and hides it from us
resource "aws_iam_instance_profile" "kandagawa_instance_profile01" {
  name = "${local.name_prefix}-instance-profile01"
  role = aws_iam_role.kandagawa_ec2_role01.name

  tags = {
    Name = "${local.name_prefix}-instance-profile01"
  }
}

# ############################################
# # EC2 Instance (App Host)
# ############################################

# # Explanation: This is your “Han Solo box”—it talks to RDS and complains loudly when the DB is down.
# resource "aws_instance" "kandagawa_ec201" {
#   ami                    = var.ec2_ami_id
#   instance_type           = var.ec2_instance_type
#   subnet_id               = aws_subnet.kandagawa_public_subnets[0].id
#   vpc_security_group_ids  = [aws_security_group.kandagawa_ec2_sg01.id]
#   iam_instance_profile    = aws_iam_instance_profile.kandagawa_instance_profile01.name

#   # TODO: student supplies user_data to install app + CW agent + configure log shipping
#   user_data = file("${path.module}/user_data.sh")

#   tags = {
#     Name = "${local.name_prefix}-ec201"
#   }
# }

############################################
# Parameter Store (SSM Parameters)
############################################

# Explanation: Parameter Store is kandagawa’s map—endpoints and config live here for fast recovery.
resource "aws_ssm_parameter" "kandagawa_db_endpoint_param" {
  name  = "/lab/db/endpoint"
  type  = "String"
  value = aws_db_instance.kandagawa_rds01.address

  tags = {
    Name = "${local.name_prefix}-param-db-endpoint"
  }
}

# Explanation: Ports are boring, but even Wookiees need to know which door number to kick in.
resource "aws_ssm_parameter" "kandagawa_db_port_param" {
  name  = "/lab/db/port"
  type  = "String"
  value = tostring(aws_db_instance.kandagawa_rds01.port)

  tags = {
    Name = "${local.name_prefix}-param-db-port"
  }
}

# Explanation: DB name is the label on the crate—without it, you’re rummaging in the dark.
resource "aws_ssm_parameter" "kandagawa_db_name_param" {
  name  = "/lab/db/name"
  type  = "String"
  value = var.db_name

  tags = {
    Name = "${local.name_prefix}-param-db-name"
  }
}

############################################
# Secrets Manager (DB Credentials)
############################################

# Explanation: Secrets Manager is kandagawa’s locked holster—credentials go here, not in code.
resource "aws_secretsmanager_secret" "kandagawa_db_secret01" {
  name = "lab/rds/mysqli"

  tags = {
    Name = "${local.name_prefix}-db-secret01"
  }
}

# Explanation: Secret payload—students should align this structure with their app (and support rotation later).
resource "aws_secretsmanager_secret_version" "kandagawa_db_secret_version01" {
  secret_id = aws_secretsmanager_secret.kandagawa_db_secret01.id

  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    host     = aws_db_instance.kandagawa_rds01.address
    port     = aws_db_instance.kandagawa_rds01.port
    dbname   = var.db_name
  })
}

############################################
# CloudWatch Logs (Log Group)
############################################

# Explanation: When the Falcon is on fire, logs tell you *which* wire sparked—ship them centrally.
resource "aws_cloudwatch_log_group" "kandagawa_log_group01" {
  name = "/aws/ec2/lab-rds-app"
  retention_in_days = 7

  tags = {
    Name = "${local.name_prefix}-log-group01"
  }
}

############################################
# Custom Metric + Alarm (Skeleton)
############################################

# Explanation: Metrics are kandagawa’s growls—when they spike, something is wrong.
# NOTE: Students must emit the metric from app/agent; this just declares the alarm.
resource "aws_cloudwatch_metric_alarm" "kandagawa_db_alarm01" {
  alarm_name          = "${local.name_prefix}-db-connection-failure"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "DBConnectionErrors"
  namespace           = "Lab/RDSApp"
  period              = 300
  statistic           = "Sum"
  threshold           = 3

  alarm_actions       = [aws_sns_topic.kandagawa_sns_topic01.arn]

  tags = {
    Name = "${local.name_prefix}-alarm-db-fail"
  }
}

############################################
# SNS (PagerDuty simulation)
############################################

# Explanation: SNS is the distress beacon—when the DB dies, the galaxy (your inbox) must hear about it.
resource "aws_sns_topic" "kandagawa_sns_topic01" {
  name = "${local.name_prefix}-db-incidents"

  tags = {
    Name = "${local.name_prefix}-sns-topic01"
  }
}

# Explanation: Email subscription (set up email to get a text message from this message from AWS)
resource "aws_sns_topic_subscription" "kandagawa_sns_sub01" {
  topic_arn = aws_sns_topic.kandagawa_sns_topic01.arn
  protocol  = "email"
  endpoint  = var.sns_email_endpoint
}

# # ############################################
# # # (Optional but realistic) VPC Endpoints (Skeleton)
# # ############################################

# # # Explanation: Endpoints keep traffic inside AWS like hyperspace lanes—less exposure, more control.
# # # TODO: students can add endpoints for SSM, Logs, Secrets Manager if doing “no public egress” variant.
# # # resource "aws_vpc_endpoint" "kandagawa_vpce_ssm" { ... }