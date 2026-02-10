terraform {
  backend "s3" {
    bucket = "success-lab3-terraform-state"
    key    = "lab-3/tokyo/terraform.tfstate"
    region = "us-east-1"
  }
}