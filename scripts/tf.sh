#!/bin/bash

# Terraform wrapper script with Vault AWS credential integration
# Usage: ./scripts/tf.sh <namespace> <plan|apply|destroy>

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print functions
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Usage function
usage() {
    echo "Usage: $0 <namespace> <plan|apply|destroy>"
    echo ""
    echo "Arguments:"
    echo "  namespace    Environment namespace (qa, data, devops)"
    echo "  action       Terraform action (plan, apply, destroy)"
    echo ""
    echo "Environment Variables:"
    echo "  VAULT_ADDR   Vault server address (required)"
    echo "  VAULT_TOKEN  Vault authentication token (required)"
    echo ""
    echo "Examples:"
    echo "  $0 qa plan"
    echo "  $0 data apply"
    echo "  $0 devops destroy"
    exit 1
}

# Check arguments
if [ $# -ne 2 ]; then
    print_error "Invalid number of arguments"
    usage
fi

NAMESPACE=$1
ACTION=$2

# Validate namespace
if [[ ! "$NAMESPACE" =~ ^(qa|data|devops)$ ]]; then
    print_error "Invalid namespace: $NAMESPACE. Must be one of: qa, data, devops"
    exit 1
fi

# Validate action
if [[ ! "$ACTION" =~ ^(plan|apply|destroy)$ ]]; then
    print_error "Invalid action: $ACTION. Must be one of: plan, apply, destroy"
    exit 1
fi

# Load .env file if it exists
if [ -f ".env" ]; then
    print_info "Loading environment variables from .env file"
    set -a
    source .env
    set +a
fi

# Check required environment variables
if [ -z "$VAULT_ADDR" ]; then
    print_error "VAULT_ADDR environment variable is required"
    print_info "Example: export VAULT_ADDR=https://abc123.ngrok-free.app"
    exit 1
fi

if [ -z "$VAULT_TOKEN" ]; then
    print_error "VAULT_TOKEN environment variable is required"
    print_info "Run: vault auth -method=userpass username=<your-username>"
    print_info "Or: vault login"
    exit 1
fi

# Check if required tools are available
command -v vault >/dev/null 2>&1 || {
    print_error "vault CLI is required but not installed"
    exit 1
}

command -v terraform >/dev/null 2>&1 || {
    print_error "terraform CLI is required but not installed"
    exit 1
}

command -v jq >/dev/null 2>&1 || {
    print_error "jq is required but not installed"
    exit 1
}

print_info "Starting Terraform operation for namespace: $NAMESPACE, action: $ACTION"

# Test Vault connectivity
print_info "Testing Vault connectivity..."
if ! vault status >/dev/null 2>&1; then
    print_error "Cannot connect to Vault at $VAULT_ADDR"
    print_info "Make sure Vault is running and VAULT_ADDR is correct"
    exit 1
fi

# Retrieve AWS credentials from Vault
print_info "Retrieving AWS credentials from Vault..."
VAULT_ROLE="${NAMESPACE}-deploy"
CREDS_JSON=$(vault read -format=json "aws/creds/$VAULT_ROLE" 2>/dev/null) || {
    print_error "Failed to retrieve AWS credentials for role: $VAULT_ROLE"
    print_info "Make sure the Vault role exists and you have permission to access it"
    exit 1
}

# Extract credentials
export AWS_ACCESS_KEY_ID=$(echo "$CREDS_JSON" | jq -r '.data.access_key')
export AWS_SECRET_ACCESS_KEY=$(echo "$CREDS_JSON" | jq -r '.data.secret_key')
export AWS_SESSION_TOKEN=$(echo "$CREDS_JSON" | jq -r '.data.security_token // empty')
export AWS_DEFAULT_REGION="us-west-1"

# Validate credentials were extracted
if [ "$AWS_ACCESS_KEY_ID" = "null" ] || [ -z "$AWS_ACCESS_KEY_ID" ]; then
    print_error "Failed to extract AWS_ACCESS_KEY_ID from Vault response"
    exit 1
fi

if [ "$AWS_SECRET_ACCESS_KEY" = "null" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
    print_error "Failed to extract AWS_SECRET_ACCESS_KEY from Vault response"
    exit 1
fi

# Check TTL and warn if too short
LEASE_DURATION=$(echo "$CREDS_JSON" | jq -r '.lease_duration')
if [ "$LEASE_DURATION" != "null" ] && [ "$LEASE_DURATION" -lt 120 ]; then
    print_warning "AWS credentials TTL is ${LEASE_DURATION}s, which is less than 120s"
    print_warning "This may not be enough time for Terraform operations"
fi

print_success "AWS credentials retrieved successfully (TTL: ${LEASE_DURATION}s)"

# Change to environment directory
ENV_DIR="envs/$NAMESPACE"
if [ ! -d "$ENV_DIR" ]; then
    print_error "Environment directory not found: $ENV_DIR"
    exit 1
fi

print_info "Changing to directory: $ENV_DIR"
cd "$ENV_DIR"

# Initialize Terraform
print_info "Initializing Terraform..."
if ! terraform init -input=false; then
    print_error "Terraform init failed"
    exit 1
fi

# Validate Terraform configuration
print_info "Validating Terraform configuration..."
if ! terraform validate; then
    print_error "Terraform validation failed"
    exit 1
fi

# Execute the requested action
case $ACTION in
    plan)
        print_info "Running Terraform plan..."
        terraform plan -input=false
        ;;
    apply)
        print_info "Running Terraform apply..."
        terraform apply -auto-approve -input=false
        if [ $? -eq 0 ]; then
            print_success "Terraform apply completed successfully"
            print_info "Outputs:"
            terraform output
        else
            print_error "Terraform apply failed"
            exit 1
        fi
        ;;
    destroy)
        print_warning "Running Terraform destroy..."
        terraform destroy -auto-approve -input=false
        if [ $? -eq 0 ]; then
            print_success "Terraform destroy completed successfully"
        else
            print_error "Terraform destroy failed"
            exit 1
        fi
        ;;
esac

print_success "Operation completed successfully!"
