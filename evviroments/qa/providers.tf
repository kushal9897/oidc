terraform {
  required_version = ">= 1.6.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# AWS Provider configured via environment variables or Vault
provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Terraform   = "true"
      Environment = "qa"
    }
  }
}