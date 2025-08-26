terraform {
  required_version = ">= 1.6.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.20"
    }
  }
}

# Vault provider - configured via environment variables
# VAULT_ADDR and VAULT_TOKEN should be set
provider "vault" {
  # Configuration is provided via environment variables:
  # export VAULT_ADDR="http://localhost:8200"
  # export VAULT_TOKEN="your-token"
}

# AWS Provider - uses credentials from Vault module
provider "aws" {
  region     = var.aws_region
  access_key = module.vault_aws.access_key
  secret_key = module.vault_aws.secret_key
  token      = module.vault_aws.security_token
  
  default_tags {
    tags = {
      Environment = "qa"
      ManagedBy   = "Terraform"
      Namespace   = "qa"
    }
  }
}