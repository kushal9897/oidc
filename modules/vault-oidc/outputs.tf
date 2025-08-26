output "aws_backend_path" {
  description = "Path to AWS secrets engine"
  value       = vault_mount.aws.path
}

output "jwt_backend_path" {
  description = "Path to JWT auth backend"
  value       = vault_jwt_auth_backend.github.path
}

output "github_actions_role" {
  description = "Name of the GitHub Actions role"
  value       = vault_jwt_auth_backend_role.github_actions.role_name
}