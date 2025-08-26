#!/bin/bash
set -e

echo "🚀 Quick Start - Setting up everything..."

# 1. Start Vault
./scripts/init-vault.sh

# 2. Setup environment
export VAULT_ADDR='http://127.0.0.1:8200'
export VAULT_TOKEN=$(jq -r '.root_token' vault/vault-keys.json)

# 3. Run bootstrap
echo "Running bootstrap..."
cd bootstrap
terraform init
terraform apply -auto-approve
cd ..

echo "✅ Setup complete! You can now deploy namespaces:"
echo "  cd namespaces/qa"
echo "  terraform init"
echo "  terraform apply"