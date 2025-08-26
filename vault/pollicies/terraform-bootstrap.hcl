# Policy for Terraform bootstrap operations

# Manage auth methods
path "auth/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Manage secret engines
path "sys/mounts/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# List existing secret engines
path "sys/mounts" {
  capabilities = ["read", "list"]
}

# Manage policies
path "sys/policies/acl/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# List existing policies
path "sys/policies/acl" {
  capabilities = ["list"]
}

# Manage AWS secrets engine
path "aws/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Manage JWT auth
path "jwt/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}