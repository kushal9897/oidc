variable "vault_backend_path" {
  description = "Path where AWS secret backend is mounted in Vault"
  type        = string
  default     = "aws"
}

variable "vault_role_name" {
  description = "Vault role name for AWS credentials"
  type        = string
  default     = "terraform-role"
}

variable "credential_type" {
  description = "Type of credential to retrieve from Vault"
  type        = string
  default     = "sts"
}

variable "ttl" {
  description = "Time to live for credentials in seconds"
  type        = number
  default     = 900  # 15 minutes
}