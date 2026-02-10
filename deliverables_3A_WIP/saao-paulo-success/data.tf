data "terraform_remote_state" "tokyo" {
  backend = "s3"
  
  config = {
    bucket = "success-lab3-terraform-state"  # Your new bucket
    key    = "lab-3/tokyo/terraform.tfstate"
    region = "us-east-1"  # Bucket region
  }
}

locals {
  tokyo_vpc_cidr     = data.terraform_remote_state.tokyo.outputs.kandagawa_vpc_cidr
  tokyo_tgw_id       = data.terraform_remote_state.tokyo.outputs.kandagawa_tgw_id
  tokyo_rds_endpoint = data.terraform_remote_state.tokyo.outputs.kandagawa_rds_endpoint
  tokyo_zone_id      = data.terraform_remote_state.tokyo.outputs.kandagawa_route53_zone_id
  tokyo_acm_cert_arn = data.terraform_remote_state.tokyo.outputs.kandagawa_acm_cert_arn  # am i built for this shit!
  name_prefix = var.project_name

  # This is so this tricky bastard will use Tokyo's Zone ID
  liberdade_zone_id = local.tokyo_zone_id 
}