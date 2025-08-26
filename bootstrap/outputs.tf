output "s3_bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  value       = module.terraform_backend.bucket_name
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table for state locking"
  value       = module.terraform_backend.dynamodb_table_name
}

output "vault_aws_role_arn" {
  description = "ARN of the IAM role for Vault"
  value       = aws_iam_role.vault_aws_secrets_role.arn
}

output "deployment_role_arn" {
  description = "ARN of the IAM role for deployments"
  value       = aws_iam_role.deployment_role.arn
}