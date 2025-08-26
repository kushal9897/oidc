#!/bin/bash

echo "Starting Vault server..."
vault server -config=vault/config.hcl &
VAULT_PID=$!

echo "Vault started with PID: $VAULT_PID"
echo $VAULT_PID > vault.pid

sleep 5

export VAULT_ADDR='http://127.0.0.1:8200'

# Unseal if needed
if [ -f "vault/vault-keys.json" ]; then
    for i in {0..2}; do
        KEY=$(jq -r ".unseal_keys_b64[$i]" vault/vault-keys.json)
        vault operator unseal $KEY
    done
    echo "✅ Vault unsealed"
fi

echo "✅ Vault is ready at $VAULT_ADDR"