#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Vault Bootstrap Script ===${NC}"

# Check if Vault is installed
if ! command -v vault &> /dev/null; then
    echo -e "${RED}Vault is not installed. Please install Vault first.${NC}"
    exit 1
fi

# Set Vault address
export VAULT_ADDR='http://127.0.0.1:8200'

# Check if Vault is already initialized
if vault status 2>/dev/null | grep -q "Initialized.*true"; then
    echo -e "${YELLOW}Vault is already initialized.${NC}"
    
    # Check if we have unseal keys stored
    if [ -f "vault-keys.json" ]; then
        echo -e "${GREEN}Found existing vault-keys.json${NC}"
        
        # Try to unseal if sealed
        if vault status 2>/dev/null | grep -q "Sealed.*true"; then
            echo -e "${YELLOW}Vault is sealed. Unsealing...${NC}"
            
            # Extract unseal keys and unseal
            for i in {0..2}; do
                KEY=$(jq -r ".unseal_keys_b64[$i]" vault-keys.json)
                vault operator unseal $KEY
            done
            
            echo -e "${GREEN}Vault unsealed successfully!${NC}"
        else
            echo -e "${GREEN}Vault is already unsealed.${NC}"
        fi
        
        # Login with root token
        ROOT_TOKEN=$(jq -r '.root_token' vault-keys.json)
        vault login $ROOT_TOKEN
    else
        echo -e "${RED}vault-keys.json not found. Please provide unseal keys manually.${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}Initializing Vault...${NC}"
    
    # Initialize Vault
    vault operator init -key-shares=5 -key-threshold=3 -format=json > vault-keys.json
    
    echo -e "${RED}CRITICAL: Save vault-keys.json in a secure location!${NC}"
    echo -e "${RED}These keys are required to unseal Vault after restart.${NC}"
    echo -e "${RED}NEVER commit this file to version control!${NC}"
    
    # Unseal Vault
    echo -e "${YELLOW}Unsealing Vault...${NC}"
    for i in {0..2}; do
        KEY=$(jq -r ".unseal_keys_b64[$i]" vault-keys.json)
        vault operator unseal $KEY
    done
    
    # Login with root token
    ROOT_TOKEN=$(jq -r '.root_token' vault-keys.json)
    vault login $ROOT_TOKEN
    
    echo -e "${GREEN}Vault initialized and unsealed successfully!${NC}"
fi

# Enable AWS secrets engine
echo -e "${YELLOW}Configuring AWS secrets engine...${NC}"
if ! vault secrets list | grep -q "^aws/"; then
    vault secrets enable aws
    echo -e "${GREEN}AWS secrets engine enabled${NC}"
else
    echo -e "${YELLOW}AWS secrets engine already enabled${NC}"
fi

# Configure AWS secrets engine
# Replace these with your actual AWS credentials
echo -e "${YELLOW}Configuring AWS credentials...${NC}"
echo -e "${RED}Enter your AWS Access Key ID:${NC}"
read -s AWS_ACCESS_KEY
echo -e "${RED}Enter your AWS Secret Access Key:${NC}"
read -s AWS_SECRET_KEY
echo -e "${RED}Enter your AWS Region (e.g., us-east-1):${NC}"
read AWS_REGION

vault write aws/config/root \
    access_key="$AWS_ACCESS_KEY" \
    secret_key="$AWS_SECRET_KEY" \
    region="$AWS_REGION"

echo -e "${GREEN}AWS root credentials configured${NC}"

# Create AWS role for deployment
echo -e "${YELLOW}Creating AWS deployment role...${NC}"
vault write aws/roles/deploy-role \
    credential_type=assumed_role \
    role_arn="$ROLE_ARN" \
    ttl=15m

echo -e "${GREEN}AWS deployment role created${NC}"

# Enable JWT auth method for GitHub Actions
echo -e "${YELLOW}Configuring JWT auth for GitHub Actions...${NC}"
if ! vault auth list | grep -q "^jwt/"; then
    vault auth enable jwt
    echo -e "${GREEN}JWT auth method enabled${NC}"
else
    echo -e "${YELLOW}JWT auth method already enabled${NC}"
fi

# Configure JWT auth for GitHub OIDC
echo -e "${RED}Enter your GitHub organization name:${NC}"
read GITHUB_ORG
echo -e "${RED}Enter your GitHub repository name:${NC}"
read GITHUB_REPO

vault write auth/jwt/config \
    bound_issuer="https://token.actions.githubusercontent.com" \
    oidc_discovery_url="https://token.actions.githubusercontent.com"

# Create role for GitHub Actions
vault write auth/jwt/role/github-actions \
    bound_audiences="vault" \
    bound_subject="repo:${GITHUB_ORG}/${GITHUB_REPO}:ref:refs/heads/main" \
    user_claim="actor" \
    role_type="jwt" \
    policies="aws-deploy" \
    ttl=15m

echo -e "${GREEN}JWT auth configured for GitHub Actions${NC}"

# Create the AWS deploy policy
echo -e "${YELLOW}Creating Vault policies...${NC}"
vault policy write aws-deploy vault/policies/aws-deploy.hcl
echo -e "${GREEN}AWS deploy policy created${NC}"

# Display summary
echo -e "${GREEN}=== Bootstrap Complete ===${NC}"
echo -e "${YELLOW}Vault is configured with:${NC}"
echo "  - AWS Secrets Engine at: aws/"
echo "  - Deployment role: aws/creds/deploy-role"
echo "  - JWT auth for GitHub Actions"
echo "  - Policy: aws-deploy"
echo ""
echo -e "${RED}IMPORTANT REMINDERS:${NC}"
echo "  1. Keep vault-keys.json secure and never commit it"
echo "  2. AWS credentials have 15-minute TTL"
echo "  3. Update GitHub secrets with VAULT_ADDR"
echo "  4. Replace placeholders in terraform files"