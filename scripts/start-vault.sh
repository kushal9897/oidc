#!/bin/bash
set -e

echo "Starting Vault server..."

# Check if vault-data directory exists
if [ ! -d "vault-data" ]; then
    mkdir -p vault-data
    echo "Created vault-data directory"
fi

# Start Vault in background
vault server -config=vault/config.hcl &
VAULT_PID=$!

echo "Vault started with PID: $VAULT_PID"
echo "Vault PID: $VAULT_PID" > vault.pid

# Wait for Vault to start
sleep 5

# Run setup script
./vault/setup.sh

echo "Vault is ready at http://127.0.0.1:8200"