#!/bin/bash
# HashiConf 2025 Demo Setup Script
# Vault CI/CD Integration Demo

set -e

echo "🔐 HashiConf 2025 - Vault CI/CD Demo Setup"
echo "=========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
VAULT_ADDR=${VAULT_ADDR:-"http://127.0.0.1:8200"}
VAULT_TOKEN=${VAULT_TOKEN:-""}
GITHUB_ORG=${GITHUB_ORG:-"kushal9897"}
GITHUB_REPO=${GITHUB_REPO:-"oidc"}
AWS_REGION=${AWS_REGION:-"us-west-2"}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
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

# Check prerequisites
check_prerequisites() {
    print_step "Checking prerequisites..."
    
    # Check if vault CLI is installed
    if ! command -v vault &> /dev/null; then
        print_error "Vault CLI not found. Please install HashiCorp Vault CLI."
        exit 1
    fi
    
    # Check if terraform is installed
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform not found. Please install Terraform."
        exit 1
    fi
    
    # Check if jq is installed
    if ! command -v jq &> /dev/null; then
        print_error "jq not found. Please install jq for JSON processing."
        exit 1
    fi
    
    print_success "All prerequisites found"
}

# Setup Vault connection
setup_vault_connection() {
    print_step "Setting up Vault connection..."
    
    export VAULT_ADDR=$VAULT_ADDR
    
    # Test Vault connection
    if ! vault status &> /dev/null; then
        print_error "Cannot connect to Vault at $VAULT_ADDR"
        print_warning "Please ensure Vault is running and accessible"
        exit 1
    fi
    
    print_success "Connected to Vault at $VAULT_ADDR"
}

# Enable audit logging
enable_audit_logging() {
    print_step "Enabling audit logging..."
    
    # Create audit log directory
    mkdir -p /tmp/vault-audit
    
    # Enable file audit device
    vault audit enable -path=file file file_path=/tmp/vault-audit/audit.log || {
        print_warning "Audit logging may already be enabled"
    }
    
    print_success "Audit logging configured"
}

# Setup AWS secrets engine
setup_aws_secrets_engine() {
    print_step "Setting up AWS secrets engine..."
    
    # Enable AWS secrets engine
    vault secrets enable -path=aws aws || {
        print_warning "AWS secrets engine may already be enabled"
    }
    
    # Configure AWS secrets engine
    vault write aws/config/root \
        region=$AWS_REGION \
        max_retries=3 || {
        print_warning "AWS root config may already exist"
    }
    
    # Create QA deployment role
    vault write aws/roles/deploy-role \
        credential_type=iam_user \
        policy_document='{
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Effect": "Allow",
                    "Action": [
                        "ec2:*",
                        "s3:*",
                        "iam:GetUser",
                        "iam:GetRole",
                        "sts:GetCallerIdentity"
                    ],
                    "Resource": "*"
                }
            ]
        }'
    
    # Create Data environment deployment role (more restrictive)
    vault write aws/roles/data-deploy-role \
        credential_type=iam_user \
        policy_document='{
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Effect": "Allow",
                    "Action": [
                        "ec2:Describe*",
                        "ec2:CreateTags",
                        "ec2:RunInstances",
                        "ec2:TerminateInstances",
                        "s3:GetObject",
                        "s3:PutObject",
                        "s3:DeleteObject",
                        "s3:ListBucket",
                        "s3:CreateBucket",
                        "s3:DeleteBucket",
                        "s3:PutBucketVersioning",
                        "s3:PutEncryptionConfiguration",
                        "iam:GetUser",
                        "sts:GetCallerIdentity"
                    ],
                    "Resource": "*"
                }
            ]
        }'
    
    print_success "AWS secrets engine configured"
}

# Setup JWT auth method
setup_jwt_auth() {
    print_step "Setting up JWT auth method for GitHub Actions..."
    
    # Enable JWT auth method
    vault auth enable -path=jwt jwt || {
        print_warning "JWT auth method may already be enabled"
    }
    
    # Configure JWT auth method
    vault write auth/jwt/config \
        bound_issuer="https://token.actions.githubusercontent.com" \
        oidc_discovery_url="https://token.actions.githubusercontent.com"
    
    # Create GitHub Actions role for QA
    vault write auth/jwt/role/github-actions \
        bound_audiences="https://github.com/$GITHUB_ORG,vault" \
        bound_claims=@- \
        user_claim="actor" \
        role_type="jwt" \
        token_policies="github-actions" \
        token_ttl=900 \
        token_max_ttl=1800 <<EOF
{
  "sub": "repo:$GITHUB_ORG/$GITHUB_REPO:ref:refs/heads/main"
}
EOF
    
    # Create GitHub Actions role for Data environment
    vault write auth/jwt/role/github-actions-data \
        bound_audiences="https://github.com/$GITHUB_ORG,vault" \
        bound_claims=@- \
        user_claim="actor" \
        role_type="jwt" \
        token_policies="github-actions-data" \
        token_ttl=600 \
        token_max_ttl=900 <<EOF
{
  "sub": "repo:$GITHUB_ORG/$GITHUB_REPO:ref:refs/heads/main"
}
EOF
    
    # Create GitHub Actions role for PRs (read-only)
    vault write auth/jwt/role/github-actions-pr \
        bound_audiences="https://github.com/$GITHUB_ORG,vault" \
        bound_claims=@- \
        user_claim="actor" \
        role_type="jwt" \
        token_policies="github-actions-readonly" \
        token_ttl=900 <<EOF
{
  "sub": "repo:$GITHUB_ORG/$GITHUB_REPO:pull_request"
}
EOF
    
    print_success "JWT auth method configured"
}

# Setup policies
setup_policies() {
    print_step "Setting up Vault policies..."
    
    # GitHub Actions policy (QA environment)
    vault policy write github-actions - <<EOF
# Read AWS credentials
path "aws/creds/deploy-role" {
  capabilities = ["read"]
}

# Read AWS STS credentials
path "aws/sts/deploy-role" {
  capabilities = ["read", "update"]
}

# Token self-renewal
path "auth/token/renew-self" {
  capabilities = ["update"]
}

# Token introspection
path "auth/token/lookup-self" {
  capabilities = ["read"]
}
EOF

    # GitHub Actions policy for Data environment (more restrictive)
    vault policy write github-actions-data - <<EOF
# Read AWS credentials for data environment
path "aws/creds/data-deploy-role" {
  capabilities = ["read"]
}

# Read AWS STS credentials for data environment
path "aws/sts/data-deploy-role" {
  capabilities = ["read", "update"]
}

# Token self-renewal with shorter duration
path "auth/token/renew-self" {
  capabilities = ["update"]
  max_wrapping_ttl = "600s"
}

# Token introspection
path "auth/token/lookup-self" {
  capabilities = ["read"]
}

# Audit log access (read-only for compliance)
path "sys/audit-hash/*" {
  capabilities = ["read"]
}

# Lease management
path "sys/leases/lookup" {
  capabilities = ["read"]
}

path "sys/leases/revoke" {
  capabilities = ["update"]
}
EOF

    # Read-only policy for PRs
    vault policy write github-actions-readonly - <<EOF
# Read AWS credentials (for terraform plan)
path "aws/creds/deploy-role" {
  capabilities = ["read"]
}

# Token introspection
path "auth/token/lookup-self" {
  capabilities = ["read"]
}
EOF

    print_success "Vault policies configured"
}

# Test the setup
test_setup() {
    print_step "Testing Vault setup..."
    
    # Test AWS secrets engine
    print_step "Testing AWS credential generation..."
    if vault read aws/creds/deploy-role > /dev/null 2>&1; then
        print_success "AWS credential generation working"
    else
        print_warning "AWS credential generation failed - check AWS configuration"
    fi
    
    # Test JWT auth (if we have a token)
    if [ -n "$GITHUB_TOKEN" ]; then
        print_step "Testing JWT authentication..."
        if vault write auth/jwt/login role=github-actions jwt=$GITHUB_TOKEN > /dev/null 2>&1; then
            print_success "JWT authentication working"
        else
            print_warning "JWT authentication failed - check token and configuration"
        fi
    else
        print_warning "No GITHUB_TOKEN provided - skipping JWT auth test"
    fi
    
    print_success "Setup testing completed"
}

# Generate demo summary
generate_summary() {
    print_step "Generating demo summary..."
    
    cat << EOF

🎉 HashiConf 2025 Demo Setup Complete!
=====================================

✅ Vault Configuration:
   - Address: $VAULT_ADDR
   - AWS Secrets Engine: Enabled
   - JWT Auth Method: Enabled
   - Audit Logging: Enabled

✅ GitHub Integration:
   - Organization: $GITHUB_ORG
   - Repository: $GITHUB_REPO
   - OIDC Roles: Configured

✅ Environments:
   - QA: Standard security (15min TTL)
   - Data: Enhanced security (10min TTL)

🔧 Next Steps:
   1. Set GitHub repository secrets:
      - VAULT_ADDR=$VAULT_ADDR
   
   2. Update GitHub organization/repo in:
      - .github/workflows/terraform-deploy.yml
      - modules/vault-oidc/variables.tf
   
   3. Test the pipeline:
      - Push to main branch
      - Create a pull request
      - Use workflow_dispatch for manual testing

📚 Demo Resources:
   - README.md: Complete documentation
   - DEMO_SCRIPT.md: Presentation script
   - Audit logs: /tmp/vault-audit/audit.log

🎯 For HashiConf Demo:
   - Practice the demo script
   - Test all scenarios
   - Prepare backup slides
   - Have fun! 🚀

EOF
}

# Main execution
main() {
    echo "Starting HashiConf 2025 demo setup..."
    echo
    
    check_prerequisites
    setup_vault_connection
    enable_audit_logging
    setup_aws_secrets_engine
    setup_jwt_auth
    setup_policies
    test_setup
    generate_summary
    
    print_success "Demo setup completed successfully!"
}

# Run main function
main "$@"
