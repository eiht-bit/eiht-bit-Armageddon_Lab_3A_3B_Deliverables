# ############################################
# # Bonus B - WAF Logging (CloudWatch Logs)
# ############################################

# resource "aws_cloudwatch_log_group" "kandagawa_waf_log_group01" {
#   count = var.enable_waf && var.waf_log_destination == "cloudwatch" ? 1 : 0

#   # AWS requires WAF log names to start with aws-waf-logs-
#   name              = "aws-waf-logs-${var.project_name}-webacl01"
#   retention_in_days = var.waf_log_retention_days

#   tags = {
#     Name = "${var.project_name}-waf-log-group01"
#   }
# }

# resource "aws_wafv2_web_acl_logging_configuration" "kandagawa_waf_logging01" {
#   count = var.enable_waf && var.waf_log_destination == "cloudwatch" ? 1 : 0

#   resource_arn = aws_wafv2_web_acl.kandagawa_waf01[0].arn
#   log_destination_configs = [
#     aws_cloudwatch_log_group.kandagawa_waf_log_group01[0].arn
#   ]

#   depends_on = [aws_wafv2_web_acl.kandagawa_waf01]
# }