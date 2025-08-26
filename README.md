# Vault + Terraform EC2 Demo

Production-ready repository demonstrating HashiCorp Vault integration with Terraform for secure AWS EC2 provisioning across multiple namespaces (qa, data, devops) using dynamic credentials and no static secrets.

## 🏗️ Architecture

```
Developer → Vault (via ngrok) → AWS Credentials → Terraform → EC2 Instances
```

**Key Features:**
- **Zero Static Credentials**: All AWS credentials retrieved dynamically from Vault
- **Namespace Isolation**: Separate environments (qa, data, devops) with dedicated IAM policies
- **Reusable Module**: EC2 instance module with security groups and sensible defaults
- **Production Ready**: S3 backend support, proper tagging, validation scripts

## 📋 Prerequisites

Install these tools before starting:

```bash
# Required tools
vault --version    # HashiCorp Vault CLI
terraform --version # Terraform >= 1.11
jq --version       # JSON processor
curl --version     # HTTP client

# Optional (for manual testing)
aws --version      # AWS CLI
```

## 🚀 Quick Start Guide

### Step 1: Start Vault Dev Server

```bash
# Start Vault in development mode
vault server -dev -dev-root-token-id=demo-root -dev-listen-address=0.0.0.0:8200
```

**Keep this terminal open** - Vault is now running on `http://localhost:8200`

### Step 2: Expose Vault with ngrok

```bash
# In a new terminal, expose Vault to the internet
ngrok http 8200
```

**Copy the HTTPS URL** (e.g., `https://abc123.ngrok-free.app`) - you'll need this next.

### Step 3: Set Environment Variables

```bash
# Set Vault connection details
export VAULT_ADDR=https://abc123.ngrok-free.app  # Your ngrok URL
export VAULT_TOKEN=demo-root

# Set AWS credentials (for Vault backend configuration)
export AWS_ACCESS_KEY_ID=your-aws-access-key
export AWS_SECRET_ACCESS_KEY=your-aws-secret-key
export AWS_REGION=us-west-1
```

### Step 4: One-Time Vault Setup

```bash
# Navigate to project directory
cd oidc/

# Enable AWS secrets engine
vault secrets enable aws

# Configure AWS backend with your credentials
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
```

### Step 5: Login to Vault

```bash
# Authenticate with Vault
vault login demo-root
```

### Step 6: Run Environment Check

```bash
# Verify everything is configured correctly
chmod +x scripts/demo-check.sh
./scripts/demo-check.sh
```

### Step 7: Deploy Infrastructure

```bash
# Make script executable
chmod +x scripts/tf.sh

# Plan QA environment
./scripts/tf.sh qa plan

# Deploy QA environment
./scripts/tf.sh qa apply

# Check outputs
cd envs/qa && terraform output
```

## 🛠️ Usage Examples

### Deploy to Different Environments

```bash
# QA Environment
./scripts/tf.sh qa plan
./scripts/tf.sh qa apply

# Data Environment  
./scripts/tf.sh data plan
./scripts/tf.sh data apply

# DevOps Environment
./scripts/tf.sh devops plan
./scripts/tf.sh devops apply
```

### Destroy Resources

```bash
# Destroy QA environment
./scripts/tf.sh qa destroy

# Destroy all environments
./scripts/tf.sh qa destroy
./scripts/tf.sh data destroy
./scripts/tf.sh devops destroy
```

### Test AWS Credential Generation

```bash
# Test credential retrieval for each namespace
vault read aws/creds/qa-deploy
vault read aws/creds/data-deploy
vault read aws/creds/devops-deploy
```

## 📁 Project Structure

```
oidc/
├── envs/                          # Environment roots
│   ├── qa/                        # QA environment
│   │   ├── main.tf               # QA Terraform config
│   │   └── outputs.tf            # QA outputs
│   ├── data/                      # Data environment
│   │   ├── main.tf               # Data Terraform config
│   │   └── outputs.tf            # Data outputs
│   └── devops/                    # DevOps environment
│       ├── main.tf               # DevOps Terraform config
│       └── outputs.tf            # DevOps outputs
├── modules/
│   └── ec2-instance/              # Reusable EC2 module
│       ├── main.tf               # EC2 + Security Group
│       ├── variables.tf          # Input variables
│       └── outputs.tf            # Module outputs
├── scripts/
│   ├── tf.sh                     # Terraform wrapper with Vault integration
│   └── demo-check.sh             # Environment validation script
├── policies/
│   ├── qa-iam.json               # QA IAM permissions
│   ├── data-iam.json             # Data IAM permissions
│   └── devops-iam.json           # DevOps IAM permissions
├── .gitignore                     # Git ignore rules
└── README.md                      # This file
```

## 🔧 EC2 Module Details

The `modules/ec2-instance` module provides:

**Inputs:**
- `instance_name` (required): Name for the EC2 instance
- `instance_type` (optional): Instance type (default: t2.micro)
- `vpc_id` (optional): VPC ID (uses default VPC if not provided)
- `subnet_id` (optional): Subnet ID (uses default subnet if not provided)
- `tags` (optional): Additional resource tags

**Outputs:**
- `instance_id`: EC2 instance ID
- `public_ip`: Public IP address
- `private_ip`: Private IP address  
- `sg_id`: Security group ID

**Features:**
- Latest Amazon Linux 2 AMI
- HTTP (port 80) and SSH (port 22) access
- Basic web server setup via user data
- Automatic public IP assignment

## 🔒 Security Configuration

### IAM Policies (Demo Only)

Each namespace has minimal EC2 permissions:
- EC2 instance management (run, terminate, describe)
- Security group management (create, delete, modify)
- VPC read access (describe VPCs, subnets)
- AMI access (describe images)
- Resource tagging

**⚠️ Security Notes:**
- SSH access is open to 0.0.0.0/0 (demo only)
- ngrok exposes Vault publicly (demo only)
- Use proper network security in production
- Implement least privilege IAM policies
- Enable Vault audit logging

### Credential TTL

AWS credentials from Vault have short TTLs:
- Default: 768 seconds (12.8 minutes)
- Minimum recommended: 120 seconds
- Script warns if TTL < 120 seconds

## 🔄 Optional: S3 Backend Setup

For production use, enable S3 backend in each environment:

1. **Create S3 bucket and DynamoDB table:**
```bash
# Create S3 bucket for state
aws s3 mb s3://your-terraform-state-bucket

# Create DynamoDB table for locking
aws dynamodb create-table \
    --table-name terraform-locks \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST
```

2. **Uncomment backend configuration** in `envs/*/main.tf`:
```hcl
backend "s3" {
  bucket         = "your-terraform-state-bucket"
  key            = "qa/terraform.tfstate"  # Change per environment
  region         = "us-west-1"
  use_lockfile   = true
  dynamodb_table = "terraform-locks"
}
```

3. **Migrate state:**
```bash
cd envs/qa
terraform init -migrate-state
```

## 🧪 Demo & Testing Checklist

### Pre-Demo Checklist
- [ ] Vault dev server running
- [ ] ngrok tunnel active and HTTPS URL noted
- [ ] Environment variables set (VAULT_ADDR, VAULT_TOKEN, AWS credentials)
- [ ] AWS secrets engine enabled and configured
- [ ] IAM roles created (qa-deploy, data-deploy, devops-deploy)
- [ ] Demo check script passes: `./scripts/demo-check.sh`

### Demo Flow
1. **Show credential retrieval:** `vault read aws/creds/qa-deploy`
2. **Plan infrastructure:** `./scripts/tf.sh qa plan`
3. **Deploy infrastructure:** `./scripts/tf.sh qa apply`
4. **Show outputs:** `cd envs/qa && terraform output`
5. **Test web server:** `curl http://<public_ip>`
6. **Clean up:** `./scripts/tf.sh qa destroy`

### Testing Commands
```bash
# Validate all environments
./scripts/demo-check.sh

# Test credential generation
vault read aws/creds/qa-deploy

# Validate Terraform configs
cd envs/qa && terraform validate
cd envs/data && terraform validate  
cd envs/devops && terraform validate

# Test web server (after deployment)
curl http://$(cd envs/qa && terraform output -raw public_ip)
```

## 🚨 Troubleshooting

### Common Issues

**Vault Connection Failed:**
```bash
# Check Vault status
vault status

# Verify VAULT_ADDR
echo $VAULT_ADDR

# Test ngrok tunnel
curl $VAULT_ADDR/v1/sys/health
```

**AWS Credentials Invalid:**
```bash
# Test AWS credentials
aws sts get-caller-identity

# Check Vault AWS config
vault read aws/config/root
```

**Terraform Validation Failed:**
```bash
# Check Terraform version
terraform version

# Validate specific environment
cd envs/qa && terraform validate
```

**Script Permission Denied:**
```bash
# Make scripts executable
chmod +x scripts/tf.sh scripts/demo-check.sh
```

### Debug Commands
```bash
# Vault status and auth
vault status
vault token lookup

# List AWS roles
vault list aws/roles

# Test credential generation with details
vault read -format=json aws/creds/qa-deploy | jq

# Terraform debug
TF_LOG=DEBUG terraform plan
```

## 🎯 What This Demo Shows

1. **Zero Static Credentials**: No AWS keys stored anywhere except Vault backend
2. **Dynamic Credential Management**: Fresh AWS credentials for each operation
3. **Namespace Isolation**: Separate IAM policies per environment
4. **Infrastructure as Code**: Terraform with reusable modules
5. **Security Best Practices**: Short TTLs, least privilege, proper tagging
6. **Production Readiness**: S3 backend support, validation scripts

Perfect for demonstrating modern secrets management and infrastructure automation patterns!!
