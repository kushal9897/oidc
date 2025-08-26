#!/bin/bash

# Demo environment check script
# Verifies all required tools and services are available

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
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_header() {
    echo -e "\n${BLUE}=== $1 ===${NC}"
}

# Check if command exists
check_command() {
    local cmd=$1
    local version_flag=${2:-"--version"}
    
    if command -v "$cmd" >/dev/null 2>&1; then
        local version=$($cmd $version_flag 2>&1 | head -1)
        print_success "$cmd is installed: $version"
        return 0
    else
        print_error "$cmd is not installed"
        return 1
    fi
}

# Main checks
print_header "Demo Environment Check"

# Check required CLI tools
print_header "CLI Tools"
check_command "vault" "version"
check_command "terraform" "version"
check_command "jq" "--version"
check_command "curl" "--version"

# Check optional tools
print_header "Optional Tools"
check_command "aws" "--version" || print_warning "AWS CLI not found (optional for manual testing)"

# Check environment variables
print_header "Environment Variables"
if [ -n "$VAULT_ADDR" ]; then
    print_success "VAULT_ADDR is set: $VAULT_ADDR"
else
    print_warning "VAULT_ADDR is not set"
fi

if [ -n "$VAULT_TOKEN" ]; then
    print_success "VAULT_TOKEN is set"
else
    print_warning "VAULT_TOKEN is not set"
fi

# Check Vault connectivity
print_header "Vault Connectivity"
if [ -n "$VAULT_ADDR" ]; then
    if vault status >/dev/null 2>&1; then
        print_success "Vault is accessible at $VAULT_ADDR"
        
        # Get Vault status details
        print_info "Vault Status:"
        vault status 2>/dev/null | while read line; do
            echo "  $line"
        done
        
        # Check if we're authenticated
        if [ -n "$VAULT_TOKEN" ]; then
            if vault token lookup >/dev/null 2>&1; then
                print_success "Vault authentication is valid"
                
                # Show token info
                print_info "Token Info:"
                vault token lookup -format=json 2>/dev/null | jq -r '
                    "  TTL: " + (.data.ttl | tostring) + "s",
                    "  Policies: " + (.data.policies | join(", "))
                ' 2>/dev/null || echo "  Unable to parse token info"
            else
                print_error "Vault token is invalid or expired"
            fi
        else
            print_warning "No Vault token set - authentication required"
        fi
    else
        print_error "Cannot connect to Vault at $VAULT_ADDR"
    fi
else
    print_warning "VAULT_ADDR not set - cannot check Vault connectivity"
fi

# Check AWS secrets engine
print_header "Vault AWS Secrets Engine"
if [ -n "$VAULT_TOKEN" ] && vault status >/dev/null 2>&1; then
    if vault secrets list | grep -q "aws/"; then
        print_success "AWS secrets engine is enabled"
        
        # Check available roles
        print_info "Available AWS roles:"
        for role in qa-deploy data-deploy devops-deploy; do
            if vault list aws/roles 2>/dev/null | grep -q "^$role$"; then
                print_success "  Role '$role' exists"
            else
                print_warning "  Role '$role' not found"
            fi
        done
    else
        print_error "AWS secrets engine is not enabled"
    fi
else
    print_warning "Cannot check AWS secrets engine (Vault not accessible)"
fi

# Check project structure
print_header "Project Structure"
required_dirs=("modules/ec2-instance" "envs/qa" "envs/data" "envs/devops" "scripts" "policies")
for dir in "${required_dirs[@]}"; do
    if [ -d "$dir" ]; then
        print_success "Directory exists: $dir"
    else
        print_error "Directory missing: $dir"
    fi
done

required_files=("scripts/tf.sh" "scripts/demo-check.sh")
for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        print_success "File exists: $file"
    else
        print_error "File missing: $file"
    fi
done

# Check Terraform configurations
print_header "Terraform Validation"
for env in qa data devops; do
    if [ -d "envs/$env" ]; then
        print_info "Validating $env environment..."
        if (cd "envs/$env" && terraform init -backend=false >/dev/null 2>&1 && terraform validate >/dev/null 2>&1); then
            print_success "  $env configuration is valid"
        else
            print_error "  $env configuration has issues"
        fi
    fi
done

print_header "Summary"
print_info "Demo environment check completed"
print_info "If any errors were found, please resolve them before running the demo"
