output "access_key" {
  description = "AWS Access Key ID"
  value       = data.vault_aws_access_credentials.creds.access_key
  sensitive   = true
}

output "secret_key" {
  description = "AWS Secret Access Key"
  value       = data.vault_aws_access_credentials.creds.secret_key
  sensitive   = true
}

output "security_token" {
  description = "AWS Security Token (for STS credentials)"
  value       = try(data.vault_aws_access_credentials.creds.security_token, null)
  sensitive   = true
}

output "lease_id" {
  description = "Vault lease ID for these credentials"
  value       = data.vault_aws_access_credentials.creds.lease_id
}

output "lease_duration" {
  description = "Lease duration in seconds"
  value       = data.vault_aws_access_credentials.creds.lease_duration
}