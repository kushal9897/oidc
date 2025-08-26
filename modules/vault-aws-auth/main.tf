# This module automatically gets AWS credentials from Vault
# No need to manually configure AWS credentials!

terraform {
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.20"
    }
  }
}

data "vault_aws_access_credentials" "creds" {
  backend = var.vault_backend_path
  role    = var.vault_role_name
  type    = "creds"   # ✅ use creds for iam_user roles
  ttl     = var.ttl
}


# Output the credentials for AWS provider
locals {
  aws_credentials = {
    access_key     = data.vault_aws_access_credentials.creds.access_key
    secret_key     = data.vault_aws_access_credentials.creds.secret_key
    security_token = try(data.vault_aws_access_credentials.creds.security_token, null)
  }
}
