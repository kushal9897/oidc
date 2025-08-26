# Vault Server Configuration with Persistent Storage

# Storage backend using integrated Raft storage
storage "raft" {
  path    = "./vault-data"
  node_id = "vault-node-1"
}

# HTTP listener
listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = true  # Only for development - use TLS in production
}

# API and cluster addresses
api_addr     = "http://127.0.0.1:8200"
cluster_addr = "http://127.0.0.1:8201"

# Enable UI
ui = true

# Disable mlock for development
disable_mlock = true

# Logging
log_level = "info"

# Default lease TTLs
default_lease_ttl = "15m"
max_lease_ttl     = "1h"