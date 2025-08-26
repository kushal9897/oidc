variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "terraform-vault-demo"
}

variable "github_org" {
  description = "GitHub organization name"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
}

variable "vault_addr" {
  description = "Vault server address"
  type        = string
  default     = "http://127.0.0.1:8200"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}