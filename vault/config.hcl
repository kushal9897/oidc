# Vault server configuration with persistent storage
# This uses integrated storage (Raft) for data persistence

# API listener configuration
listener "tcp" {
  address     = "127.0.0.1:8200"
  tls_disable = true  # Only for local development - use TLS in production
}

# Storage backend - Raft for persistence
storage "raft" {
  path    = "./vault-data"
  node_id = "node1"
}

# API address for CLI access
api_addr = "http://127.0.0.1:8200"
cluster_addr = "http://127.0.0.1:8201"

# UI configuration
ui = true

# Logging
log_level = "info"

# Disable mlock for development (enable in production)
disable_mlock = true

# Default and max lease TTLs
default_lease_ttl = "15m"
max_lease_ttl = "1h"