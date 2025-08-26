# Data Environment
# Provisions EC2 instance for Data namespace

terraform {
  required_version = ">= 1.11"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Local state (default for demo)
  # Uncomment below for S3 backend in production
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "data/terraform.tfstate"
  #   region         = "us-west-1"
  #   use_lockfile   = true
  #   dynamodb_table = "terraform-locks"
  # }
}

# AWS Provider
provider "aws" {
  region = "us-west-1"
  
  # Credentials will be provided via environment variables
  # from Vault at runtime - no static credentials here
}

# EC2 Instance Module
module "data_instance" {
  source = "../../modules/ec2-instance"

  instance_name = "data-demo-instance"
  instance_type = "t2.micro"

  tags = {
    Environment = "data"
    Project     = "vault-demo"
    ManagedBy   = "terraform"
    Namespace   = "data"
  }
}
