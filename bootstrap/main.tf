# Bootstrap configuration - Sets up Vault and initial AWS resources

terraform {
  required_version = ">= 1.6.0"
  
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.20"
    }
  }
}

provider "vault" {
  # Configured via environment variables (VAULT_ADDR, VAULT_TOKEN)
}

# Enable + configure AWS secrets engine
resource "vault_aws_secret_backend" "aws" {
  path   = "aws"
  region = var.aws_region
  
  access_key = var.aws_access_key_id
  secret_key = var.aws_secret_access_key
  
  default_lease_ttl_seconds = 900   # 15 minutes
  max_lease_ttl_seconds     = 1800  # 30 minutes
}

# Create Terraform role in Vault (works with root creds)
resource "vault_aws_secret_backend_role" "terraform" {
  backend         = vault_aws_secret_backend.aws.path
  name            = "terraform-role"
  credential_type = "iam_user"

  policy_document = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "ec2:*",
          "s3:*",
          "iam:GetUser",
          "iam:GetRole",
          "sts:GetCallerIdentity"
        ]
        Resource = "*"
      }
    ]
  })
}

# Enable JWT auth for GitHub Actions
resource "vault_jwt_auth_backend" "github" {
  description        = "JWT auth for GitHub Actions"
  path               = "jwt"
  oidc_discovery_url = "https://token.actions.githubusercontent.com"
  bound_issuer       = "https://token.actions.githubusercontent.com"
}

# Create role for GitHub Actions
resource "vault_jwt_auth_backend_role" "github_actions" {
  backend   = vault_jwt_auth_backend.github.path
  role_name = "github-actions"
  
  token_policies = ["terraform-policy"]
  
  bound_audiences = ["https://github.com/${var.github_org}", "vault"]
  bound_subject   = "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/main"
  
  user_claim = "actor"
  role_type  = "jwt"
  token_ttl  = 900
}

# Create policy for Terraform
resource "vault_policy" "terraform" {
  name = "terraform-policy"
  
  policy = <<EOT
# Read AWS credentials
path "aws/creds/terraform-role" {
  capabilities = ["read"]
}

# Token renewal
path "auth/token/renew-self" {
  capabilities = ["update"]
}

path "auth/token/lookup-self" {
  capabilities = ["read"]
}
EOT
}

output "vault_aws_path" {
  value = vault_aws_secret_backend.aws.path
}

output "vault_role_name" {
  value = vault_aws_secret_backend_role.terraform.name
}
