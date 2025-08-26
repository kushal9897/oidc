# Bootstrap configuration - Run this first to set up AWS backend and Vault OIDC
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

# Data source for current AWS account
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Generate unique bucket name
locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
  project_name = var.project_name
  
  bucket_name = "terraform-state-${local.account_id}-${local.region}"
  
  common_tags = {
    Project     = local.project_name
    ManagedBy   = "Terraform"
    Environment = "Bootstrap"
    Purpose     = "Infrastructure State Management"
  }
}

# Create S3 bucket for Terraform state
module "terraform_backend" {
  source = "../modules/aws-backend"
  
  bucket_name    = local.bucket_name
  dynamodb_table = "terraform-state-lock"
  tags          = local.common_tags
}

# Configure Vault OIDC
module "vault_oidc" {
  source = "../modules/vault-oidc"
  
  github_org        = var.github_org
  github_repo       = var.github_repo
  aws_account_id    = local.account_id
  aws_region        = local.region
  project_name      = local.project_name
  vault_addr        = var.vault_addr
}

# Create IAM role for Vault to assume
resource "aws_iam_role" "vault_aws_secrets_role" {
  name = "${local.project_name}-vault-secrets-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${local.account_id}:root"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
  
  tags = local.common_tags
}

# Attach policies to Vault role
resource "aws_iam_role_policy_attachment" "vault_iam_full" {
  role       = aws_iam_role.vault_aws_secrets_role.name
  policy_arn = "arn:aws:iam::aws:policy/IAMFullAccess"
}

resource "aws_iam_role_policy_attachment" "vault_sts_full" {
  role       = aws_iam_role.vault_aws_secrets_role.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

# Create IAM role for deployments
resource "aws_iam_role" "deployment_role" {
  name = "${local.project_name}-deployment-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${local.account_id}:root"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
  
  tags = local.common_tags
}

# Create deployment policy
resource "aws_iam_policy" "deployment_policy" {
  name = "${local.project_name}-deployment-policy"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EC2Permissions"
        Effect = "Allow"
        Action = [
          "ec2:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "S3Permissions"
        Effect = "Allow"
        Action = [
          "s3:*"
        ]
        Resource = [
          "arn:aws:s3:::${local.project_name}-*",
          "arn:aws:s3:::${local.project_name}-*/*",
          "arn:aws:s3:::${local.bucket_name}",
          "arn:aws:s3:::${local.bucket_name}/*"
        ]
      },
      {
        Sid    = "IAMReadPermissions"
        Effect = "Allow"
        Action = [
          "iam:GetRole",
          "iam:GetPolicy",
          "iam:ListRoles",
          "iam:ListPolicies",
          "sts:GetCallerIdentity"
        ]
        Resource = "*"
      },
      {
        Sid    = "DynamoDBStateLock"
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem",
          "dynamodb:DescribeTable"
        ]
        Resource = "arn:aws:dynamodb:${local.region}:${local.account_id}:table/terraform-state-lock"
      }
    ]
  })
  
  tags = local.common_tags
}

# Attach policy to deployment role
resource "aws_iam_role_policy_attachment" "deployment_policy_attach" {
  role       = aws_iam_role.deployment_role.name
  policy_arn = aws_iam_policy.deployment_policy.arn
}

# Generate backend configuration files for environments
resource "local_file" "backend_config" {
  for_each = toset(["qa", "production"])
  
  content = templatefile("${path.module}/templates/backend.tf.tpl", {
    bucket         = local.bucket_name
    key           = "${local.project_name}/${each.key}/terraform.tfstate"
    region        = local.region
    dynamodb_table = "terraform-state-lock"
  })
  
  filename = "${path.module}/../environments/${each.key}/backend.tf.generated"
}