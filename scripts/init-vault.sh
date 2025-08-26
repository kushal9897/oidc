#!/bin/bash
set -e

echo "🔐 Initializing Vault for Terraform..."

# Start Vault if not running
if ! pgrep -x "vault" > /dev/null; then
    echo "Starting Vault server..."
    vault server -config=vault/config.hcl &
    sleep 5
fi

# Run setup
cd vault && ./setup.sh && cd ..

# Export environment variables
export VAULT_ADDR='http://127.0.0.1:8200'
export VAULT_TOKEN=$(jq -r '.root_token' vault/vault-keys.json)

echo "✅ Vault initialized and ready!"
echo ""
echo "Environment variables set:"
echo "  VAULT_ADDR=$VAULT_ADDR"
echo "  VAULT_TOKEN=<hidden>"