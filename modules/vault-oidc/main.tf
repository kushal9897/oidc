# Simple Vault AWS Secrets Engine and GitHub OIDC

terraform {
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.20"
    }
  }
}

# Enable AWS secrets engine
resource "vault_mount" "aws" {
  path = "aws"
  type = "aws"
  
  description = "AWS secrets engine for dynamic credentials"
  
  default_lease_ttl_seconds = 900  # 15 minutes
  max_lease_ttl_seconds     = 3600 # 1 hour
}

# Configure AWS secrets engine
resource "vault_aws_secret_backend" "aws" {
  path   = vault_mount.aws.path
  region = var.aws_region
  
  default_lease_ttl_seconds = 900
  max_lease_ttl_seconds     = 3600
}

# Create AWS role for deployments
resource "vault_aws_secret_backend_role" "deploy" {
  backend = vault_mount.aws.path
  name    = "deploy-role"
  
  credential_type = "iam_user"
  
  policy_document = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
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
  
  default_sts_ttl = 900
  max_sts_ttl     = 3600
}

# Enable JWT auth method for GitHub Actions
resource "vault_jwt_auth_backend" "github" {
  path               = "jwt"
  type               = "jwt"
  description        = "JWT auth for GitHub Actions OIDC"
  
  oidc_discovery_url = "https://token.actions.githubusercontent.com"
  bound_issuer       = "https://token.actions.githubusercontent.com"
}

# Create role for GitHub Actions
resource "vault_jwt_auth_backend_role" "github_actions" {
  backend   = vault_jwt_auth_backend.github.path
  role_name = "github-actions"
  
  token_policies = ["github-actions"]
  
  bound_audiences = ["https://github.com/${var.github_org}", "vault"]
  
  bound_claims = {
    sub = "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/main"
  }
  
  user_claim = "actor"
  role_type  = "jwt"
  token_ttl  = 900
}

# Create role for GitHub Actions PRs
resource "vault_jwt_auth_backend_role" "github_actions_pr" {
  backend   = vault_jwt_auth_backend.github.path
  role_name = "github-actions-pr"
  
  token_policies = ["github-actions-readonly"]
  
  bound_audiences = ["https://github.com/${var.github_org}", "vault"]
  
  bound_claims = {
    sub = "repo:${var.github_org}/${var.github_repo}:pull_request"
  }
  
  user_claim = "actor"
  role_type  = "jwt"
  token_ttl  = 900
}

# Create policy for GitHub Actions
resource "vault_policy" "github_actions" {
  name = "github-actions"
  
  policy = <<-EOT
    # Read AWS credentials
    path "aws/creds/deploy-role" {
      capabilities = ["read"]
    }
    
    # Token self-renewal
    path "auth/token/renew-self" {
      capabilities = ["update"]
    }
    
    # Token introspection
    path "auth/token/lookup-self" {
      capabilities = ["read"]
    }
  EOT
}

# Create read-only policy for PRs
resource "vault_policy" "github_actions_readonly" {
  name = "github-actions-readonly"
  
  policy = <<-EOT
    # Read AWS credentials (for terraform plan)
    path "aws/creds/deploy-role" {
      capabilities = ["read"]
    }
    
    # Token introspection
    path "auth/token/lookup-self" {
      capabilities = ["read"]
    }
  EOT
}