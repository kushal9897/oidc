variable "github_org" {
  description = "GitHub organization name"
  type        = string
  default     = "kushal9897"
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
  default     = "oidc"
}

variable "aws_account_id" {
  description = "AWS account ID"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "vault_addr" {
  description = "Vault server address"
  type        = string
}