#!/bin/bash
set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}════════════════════════════════════════${NC}"
echo -e "${BLUE}   Terraform Vault OIDC Project Setup   ${NC}"
echo -e "${BLUE}════════════════════════════════════════${NC}"

# Step 1: Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"

check_command() {
    if ! command -v $1 &> /dev/null; then
        echo "❌ $1 is not installed"
        exit 1
    else
        echo "✅ $1 is installed"
    fi
}

check_command terraform
check_command vault
check_command aws
check_command jq
check_command ngrok

# Step 2: Start Vault
echo -e "${YELLOW}Starting Vault server...${NC}"
./scripts/start-vault.sh

# Step 3: Get AWS credentials
echo -e "${YELLOW}Configuring AWS credentials...${NC}"
if [ -z "$AWS_ACCESS_KEY_ID" ]; then
    echo "Enter your AWS Access Key ID:"
    read -s AWS_ACCESS_KEY_ID
    export AWS_ACCESS_KEY_ID
fi

if [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
    echo "Enter your AWS Secret Access Key:"
    read -s AWS_SECRET_ACCESS_KEY
    export AWS_SECRET_ACCESS_KEY
fi

# Step 4: Run bootstrap
echo -e "${YELLOW}Running Terraform bootstrap...${NC}"
cd bootstrap

# Update terraform.tfvars
echo "Enter your GitHub organization:"
read GITHUB_ORG
echo "Enter your GitHub repository name:"
read GITHUB_REPO

cat > terraform.tfvars <<EOF
project_name = "terraform-vault-demo"
github_org   = "$GITHUB_ORG"
github_repo  = "$GITHUB_REPO"
aws_region   = "us-east-1"
vault_addr   = "http://127.0.0.1:8200"
EOF

# Initialize and apply
terraform init
terraform apply -auto-approve

cd ..

# Step 5: Expose Vault with ngrok
echo -e "${YELLOW}Exposing Vault with ngrok...${NC}"
./scripts/expose-vault.sh

echo -e "${GREEN}════════════════════════════════════════${NC}"
echo -e "${GREEN}        Setup Complete! 🎉              ${NC}"
echo -e "${GREEN}════════════════════════════════════════${NC}"