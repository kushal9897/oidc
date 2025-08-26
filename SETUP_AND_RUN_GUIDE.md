# Complete Setup and Run Guide

## 🚀 Pre-Demo Setup (One-Time)

### Step 1: Install Prerequisites

**Windows (PowerShell as Administrator):**
```powershell
# Install Chocolatey (if not installed)
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install required tools
choco install vault terraform jq curl ngrok

# Verify installations
vault --version
terraform --version
jq --version
curl --version
ngrok --version
```

**macOS:**
```bash
# Install Homebrew (if not installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install required tools
brew install vault terraform jq curl ngrok

# Verify installations
vault --version
terraform --version
jq --version
curl --version
ngrok --version
```

**Linux (Ubuntu/Debian):**
```bash
# Update package list
sudo apt update

# Install jq and curl
sudo apt install -y jq curl

# Install Vault
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt update && sudo apt install vault

# Install Terraform
sudo apt install terraform

# Install ngrok
curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null
echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | sudo tee /etc/apt/sources.list.d/ngrok.list
sudo apt update && sudo apt install ngrok
```

### Step 2: Configure AWS Credentials

**Option A: AWS CLI (Recommended)**
```bash
# Install AWS CLI
# Windows: choco install awscli
# macOS: brew install awscli
# Linux: sudo apt install awscli

# Configure AWS credentials
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Default region: us-west-1
# Default output format: json

# Test AWS access
aws sts get-caller-identity
```

**Option B: Environment Variables**
```bash
export AWS_ACCESS_KEY_ID=your-access-key-here
export AWS_SECRET_ACCESS_KEY=your-secret-key-here
export AWS_DEFAULT_REGION=us-west-1
```

### Step 3: Setup ngrok Account (Free)

```bash
# Sign up at https://ngrok.com (free account)
# Get your auth token from dashboard

# Configure ngrok
ngrok config add-authtoken your-auth-token-here
```

## 🎯 Demo Execution Guide

### Phase 1: Start Core Services

**Terminal 1 - Start Vault:**
```bash
# Navigate to project directory
cd c:/Users/kushal\ agrawal/Desktop/yoidc/oidc

# Start Vault dev server
vault server -dev -dev-root-token-id=demo-root -dev-listen-address=0.0.0.0:8200
```
**Keep this terminal open!** Vault is now running on http://localhost:8200

**Terminal 2 - Start ngrok:**
```bash
# Expose Vault to internet
ngrok http 8200
```
**Copy the HTTPS URL** (e.g., `https://abc123.ngrok-free.app`) - you'll need this!

### Phase 2: Configure Environment

**Terminal 3 - Setup Environment:**
```bash
# Navigate to project
cd c:/Users/kushal\ agrawal/Desktop/yoidc/oidc

# Set Vault connection (use YOUR ngrok URL)
export VAULT_ADDR=https://abc123.ngrok-free.app
export VAULT_TOKEN=demo-root

# Set AWS credentials for Vault backend
export AWS_ACCESS_KEY_ID=your-aws-access-key
export AWS_SECRET_ACCESS_KEY=your-aws-secret-key
export AWS_REGION=us-west-1

# Test Vault connection
vault status
```

### Phase 3: One-Time Vault Setup

```bash
# Enable AWS secrets engine
vault secrets enable aws

# Configure AWS backend
vault write aws/config/root \
    access_key=$AWS_ACCESS_KEY_ID \
    secret_key=$AWS_SECRET_ACCESS_KEY \
    region=$AWS_REGION

# Create IAM roles for each namespace
vault write aws/roles/qa-deploy \
    credential_type=iam_user \
    policy_document=@policies/qa-iam.json

vault write aws/roles/data-deploy \
    credential_type=iam_user \
    policy_document=@policies/data-iam.json

vault write aws/roles/devops-deploy \
    credential_type=iam_user \
    policy_document=@policies/devops-iam.json

# Verify roles created
vault list aws/roles
```

### Phase 4: Validate Setup

```bash
# Run environment check
./scripts/demo-check.sh

# Test credential generation
vault read aws/creds/qa-deploy
vault read aws/creds/data-deploy
vault read aws/creds/devops-deploy
```

## 🎪 Demo Execution

### Demo Script 1: QA Environment

```bash
# Show dynamic credential retrieval
echo "=== Retrieving AWS Credentials from Vault ==="
vault read aws/creds/qa-deploy

# Plan infrastructure
echo "=== Planning QA Infrastructure ==="
./scripts/tf.sh qa plan

# Deploy infrastructure
echo "=== Deploying QA Infrastructure ==="
./scripts/tf.sh qa apply

# Show results
echo "=== QA Environment Outputs ==="
cd envs/qa && terraform output

# Test web server
echo "=== Testing Web Server ==="
PUBLIC_IP=$(terraform output -raw public_ip)
curl http://$PUBLIC_IP

# Return to root
cd ../..
```

### Demo Script 2: Multi-Environment

```bash
# Deploy all environments
echo "=== Deploying All Environments ==="
./scripts/tf.sh qa apply
./scripts/tf.sh data apply
./scripts/tf.sh devops apply

# Show all outputs
echo "=== All Environment Outputs ==="
echo "QA Environment:"
cd envs/qa && terraform output && cd ../..

echo "Data Environment:"
cd envs/data && terraform output && cd ../..

echo "DevOps Environment:"
cd envs/devops && terraform output && cd ../..
```

### Demo Script 3: Cleanup

```bash
# Destroy all environments
echo "=== Cleaning Up All Environments ==="
./scripts/tf.sh qa destroy
./scripts/tf.sh data destroy
./scripts/tf.sh devops destroy

# Verify cleanup
echo "=== Verifying Cleanup ==="
aws ec2 describe-instances --region us-west-1 --query 'Reservations[*].Instances[?State.Name==`running`].[InstanceId,Tags[?Key==`Project`].Value|[0]]' --output table
```

## 🔧 Troubleshooting Guide

### Common Issues and Solutions

**1. Vault Connection Failed**
```bash
# Check Vault status
vault status

# Verify VAULT_ADDR
echo $VAULT_ADDR

# Test ngrok tunnel
curl $VAULT_ADDR/v1/sys/health
```

**2. AWS Credentials Invalid**
```bash
# Test AWS credentials
aws sts get-caller-identity

# Check Vault AWS config
vault read aws/config/root

# Verify IAM permissions
aws iam get-user
```

**3. Terraform Validation Failed**
```bash
# Check Terraform version
terraform version

# Initialize and validate
cd envs/qa
terraform init
terraform validate
cd ../..
```

**4. Script Permission Denied**
```bash
# Make scripts executable (Linux/macOS)
chmod +x scripts/tf.sh scripts/demo-check.sh

# Windows: Run in Git Bash or WSL
```

**5. ngrok Tunnel Issues**
```bash
# Check ngrok status
curl http://localhost:4040/api/tunnels

# Restart ngrok
pkill ngrok
ngrok http 8200
```

### Debug Commands

```bash
# Vault debugging
vault status
vault token lookup
vault list aws/roles
vault read -format=json aws/creds/qa-deploy | jq

# Terraform debugging
export TF_LOG=DEBUG
terraform plan

# AWS debugging
aws sts get-caller-identity
aws ec2 describe-instances --region us-west-1
```

## 📝 Demo Talking Points

### Security Benefits
- **No static credentials** in code or configuration
- **Dynamic credential generation** with automatic expiration
- **Namespace isolation** with separate IAM policies
- **Audit trail** of all credential requests
- **Short TTLs** reduce blast radius

### Operational Benefits
- **Consistent deployments** across environments
- **Automated credential management** reduces human error
- **Infrastructure as Code** with version control
- **Scalable architecture** for multiple environments
- **Production-ready patterns** with S3 backend support

### Technical Highlights
- **Vault AWS Secrets Engine** for dynamic IAM users
- **Terraform modules** for reusable infrastructure
- **Shell scripting** for automation and validation
- **Cross-platform compatibility** (Windows/macOS/Linux)
- **Modern DevOps practices** with proper separation of concerns

## 🎯 Demo Flow Summary

1. **Setup** (5 minutes): Start Vault, ngrok, configure environment
2. **Configuration** (3 minutes): Enable AWS secrets engine, create roles
3. **Validation** (2 minutes): Run checks, test credential generation
4. **Demo** (10 minutes): Deploy infrastructure, show outputs, test
5. **Cleanup** (3 minutes): Destroy resources, verify cleanup

**Total Demo Time: ~25 minutes**

This guide provides everything needed to successfully demonstrate modern secrets management and infrastructure automation patterns using HashiCorp Vault and Terraform!
