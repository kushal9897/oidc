# Policy for GitHub Actions to read AWS credentials

# Allow reading AWS credentials
path "aws/creds/deploy-role" {
  capabilities = ["read"]
}

# Allow token renewal
path "auth/token/renew-self" {
  capabilities = ["update"]
}

# Allow token lookup
path "auth/token/lookup-self" {
  capabilities = ["read"]
}

# Allow reading AWS STS credentials
path "aws/sts/deploy-role" {
  capabilities = ["read", "update"]
}