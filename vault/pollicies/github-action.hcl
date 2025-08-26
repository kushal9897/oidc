# Policy for GitHub Actions

# Read AWS credentials
path "aws/creds/deploy-role" {
  capabilities = ["read"]
}

# Read AWS STS credentials
path "aws/sts/deploy-role" {
  capabilities = ["read", "update"]
}

# Token self-renewal
path "auth/token/renew-self" {
  capabilities = ["update"]
}

# Token introspection
path "auth/token/lookup-self" {
  capabilities = ["read"]
}