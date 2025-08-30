# Policy for Terraform to read AWS credentials
path "aws/creds/terraform-role" {
  capabilities = ["read"]
}

path "aws/sts/terraform-role" {
  capabilities = ["read"]
}

path "auth/token/renew-self" {
  capabilities = ["update"]
}

path "auth/token/lookup-self" {
  capabilities = ["read"]
}

# Allow creating child tokens for Vault provider operations
path "auth/token/create" {
  capabilities = ["create", "update"]
}

# Allow token renewal and revocation
path "auth/token/renew" {
  capabilities = ["update"]
}

path "auth/token/revoke" {
  capabilities = ["update"]
}