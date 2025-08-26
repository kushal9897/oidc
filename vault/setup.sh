#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Vault Setup and Configuration     ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"

# Check if Vault is running
export VAULT_ADDR='http://127.0.0.1:8200'

if ! vault status &>/dev/null; then
    echo -e "${YELLOW}Vault is not running or not initialized${NC}"
    
    # Check if Vault is initialized
    if [ -f "vault-keys.json" ]; then
        echo -e "${GREEN}Found existing vault-keys.json${NC}"
        echo -e "${YELLOW}Starting unsealing process...${NC}"
        
        # Unseal Vault
        for i in {0..2}; do
            KEY=$(jq -r ".unseal_keys_b64[$i]" vault-keys.json)
            vault operator unseal $KEY
        done
        
        # Login with root token
        ROOT_TOKEN=$(jq -r '.root_token' vault-keys.json)
        vault login -no-print $ROOT_TOKEN
        
        echo -e "${GREEN}✓ Vault unsealed and authenticated${NC}"
    else
        echo -e "${YELLOW}Initializing new Vault instance...${NC}"
        
        # Initialize Vault
        vault operator init -key-shares=5 -key-threshold=3 -format=json > vault-keys.json
        
        echo -e "${RED}╔════════════════════════════════════════╗${NC}"
        echo -e "${RED}║           CRITICAL WARNING!            ║${NC}"
        echo -e "${RED}║  vault-keys.json has been created     ║${NC}"
        echo -e "${RED}║  Store this file securely!            ║${NC}"
        echo -e "${RED}║  NEVER commit to version control!     ║${NC}"
        echo -e "${RED}╚════════════════════════════════════════╝${NC}"
        
        # Unseal Vault
        echo -e "${YELLOW}Unsealing Vault...${NC}"
        for i in {0..2}; do
            KEY=$(jq -r ".unseal_keys_b64[$i]" vault-keys.json)
            vault operator unseal $KEY
        done
        
        # Login with root token
        ROOT_TOKEN=$(jq -r '.root_token' vault-keys.json)
        vault login -no-print $ROOT_TOKEN
        
        echo -e "${GREEN}✓ Vault initialized and unsealed${NC}"
    fi
else
    echo -e "${GREEN}Vault is already running${NC}"
    
    # Check if we're authenticated
    if ! vault token lookup &>/dev/null; then
        if [ -f "vault-keys.json" ]; then
            ROOT_TOKEN=$(jq -r '.root_token' vault-keys.json)
            vault login -no-print $ROOT_TOKEN
            echo -e "${GREEN}✓ Authenticated to Vault${NC}"
        else
            echo -e "${RED}Error: vault-keys.json not found. Cannot authenticate.${NC}"
            exit 1
        fi
    fi
fi

# Create initial policies
echo -e "${YELLOW}Creating Vault policies...${NC}"
vault policy write terraform-bootstrap vault/policies/terraform-bootstrap.hcl
vault policy write github-actions vault/policies/github-actions.hcl
echo -e "${GREEN}✓ Policies created${NC}"

# Display status
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║         Vault Setup Complete!          ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Vault Status:${NC}"
vault status
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Keep vault-keys.json secure"
echo "2. Run: make bootstrap"
echo "3. Configure GitHub secrets"