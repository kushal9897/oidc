# Enhanced Policy for GitHub Actions - Data Environment
# More restrictive permissions for production-like data environment

# Read AWS credentials for data environment (restricted role)
path "aws/creds/data-deploy-role" {
  capabilities = ["read"]
}

# Read AWS STS credentials for data environment
path "aws/sts/data-deploy-role" {
  capabilities = ["read", "update"]
}

# Token self-renewal with shorter duration
path "auth/token/renew-self" {
  capabilities = ["update"]
  max_wrapping_ttl = "600s"
}

# Token introspection
path "auth/token/lookup-self" {
  capabilities = ["read"]
}

# Audit log access (read-only for compliance)
path "sys/audit-hash/*" {
  capabilities = ["read"]
}

# Lease management (for cleanup)
path "sys/leases/lookup" {
  capabilities = ["read"]
}

path "sys/leases/revoke" {
  capabilities = ["update"]
}

# Deny access to sensitive paths
path "sys/mounts" {
  capabilities = ["deny"]
}

path "sys/auth" {
  capabilities = ["deny"]
}

path "sys/policies/*" {
  capabilities = ["deny"]
}
