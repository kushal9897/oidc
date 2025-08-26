#!/bin/bash
set -e

echo "🔐 Setting up Vault..."

export VAULT_ADDR='http://127.0.0.1:8200'

# Check if Vault is initialized
if vault status 2>/dev/null | grep -q "Initialized.*false"; then
    echo "Initializing Vault..."
    vault operator init -key-shares=5 -key-threshold=3 -format=json > vault-keys.json
    echo "✅ Vault initialized. Keys saved to vault-keys.json"
    echo "⚠️  SAVE vault-keys.json SECURELY!"
fi

# Unseal Vault
if vault status 2>/dev/null | grep -q "Sealed.*true"; then
    echo "Unsealing Vault..."
    for i in {0..2}; do
        KEY=$(jq -r ".unseal_keys_b64[$i]" vault-keys.json)
        vault operator unseal $KEY
    done
    echo "✅ Vault unsealed"
fi

# Login to Vault
ROOT_TOKEN=$(jq -r '.root_token' vault-keys.json)
vault login -no-print $ROOT_TOKEN

echo "✅ Vault setup complete!"
vault status