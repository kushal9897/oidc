# Complete Setup Guide - Vault CI/CD Demo

This guide will walk you through setting up the entire Vault CI/CD integration demo from scratch.

## Prerequisites

1. **HashiCorp Vault** (running and accessible)
2. **AWS Account** with administrative access
3. **GitHub Repository** with Actions enabled
4. **Local Tools**:
   - `vault` CLI
   - `terraform` CLI
   - `jq` (for JSON processing)

## Step 1: AWS Setup

### 1.1 Create AWS IAM User for Vault
```bash
# Create IAM user for Vault to manage dynamic credentials
aws iam create-user --user-name vault-demo-user

# Create access key for this user
aws iam create-access-key --user-name vault-demo-user
```

### 1.2 Attach Policy to Vault User
Create policy file `vault-policy.json`:
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "iam:CreateUser",
                "iam:DeleteUser",
                "iam:CreateAccessKey",
                "iam:DeleteAccessKey",
                "iam:AttachUserPolicy",
                "iam:DetachUserPolicy",
                "iam:PutUserPolicy",
                "iam:DeleteUserPolicy",
                "iam:GetUser"
            ],
            "Resource": "*"
        }
    ]
}
```

```bash
# Create and attach policy
aws iam create-policy --policy-name VaultDemoPolicy --policy-document file://vault-policy.json
aws iam attach-user-policy --user-name vault-demo-user --policy-arn arn:aws:iam::YOUR_ACCOUNT:policy/VaultDemoPolicy
```

**Save the Access Key ID and Secret Access Key - you'll need them for Vault configuration.**

## Step 2: Vault Setup

### 2.1 Expose Vault with ngrok
Since GitHub Actions runners need to access Vault, we'll use ngrok to expose your local Vault instance:

```bash
# Install ngrok if not already installed
# Download from https://ngrok.com/download

# Start Vault (if not running)
vault server -dev -dev-root-token-id="myroot" -dev-listen-address="0.0.0.0:8200"

# In another terminal, expose Vault with ngrok
ngrok http 8200
```

**Copy the ngrok HTTPS URL** (e.g., `https://abc123.ngrok.io`) - you'll need this for GitHub secrets.

### 2.2 Set Environment Variables
```bash
export VAULT_ADDR="https://    https://6aa4bcc18ade.ngrok-free.app"  # Use your ngrok URL
export VAULT_TOKEN="myroot"  # or your vault token
export AWS_ACCESS_KEY_ID="AKIA..."  # From Step 1
export AWS_SECRET_ACCESS_KEY="..."  # From Step 1
```

### 2.3 Run the Setup Script
```bash
# Make script executable
chmod +x scripts/demo-setup.sh

# Set your GitHub details
export GITHUB_ORG="your-github-org"
export GITHUB_REPO="your-repo-name"
export AWS_REGION="us-west-2"  # or your preferred region

# Run setup
./scripts/demo-setup.sh
```

### 🚀 **Easy Start Commands**

```bash
# 1. Start ngrok tunnel for Vault
ngrok http 8200

# 2. Set your details (use ngrok URL from step 1)
export VAULT_ADDR="https://6aa4bcc18ade.ngrok-free.app"
export GITHUB_ORG="kushal9897"
export GITHUB_REPO="oidc" 
export AWS_REGION="us-west-2"

# 3. Run the setup script
./scripts/demo-setup.sh

# 4. Test it works
vault read aws/creds/deploy-role
```

### 2.4 Manual Vault Configuration (if script fails)

#### Enable AWS Secrets Engine
```bash
vault secrets enable aws

# Configure with your AWS credentials
vault write aws/config/root \
    access_key=$AWS_ACCESS_KEY_ID \
    secret_key=$AWS_SECRET_ACCESS_KEY \
    region=us-west-2
```

#### Create AWS Role
```bash
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
```

#### Enable JWT Auth
```bash
vault auth enable jwt

vault write auth/jwt/config \
    bound_issuer="https://token.actions.githubusercontent.com" \
    oidc_discovery_url="https://token.actions.githubusercontent.com"
```

#### Create GitHub Actions Role
```bash
vault write auth/jwt/role/github-actions \
    bound_audiences="https://github.com/YOUR_ORG,vault" \
    bound_claims='{"sub":"repo:YOUR_ORG/YOUR_REPO:ref:refs/heads/main"}' \
    user_claim="actor" \
    role_type="jwt" \
    token_policies="github-actions" \
    token_ttl=900
```

#### Create Policies
```bash
# Main policy
vault policy write github-actions - <<EOF
path "aws/creds/deploy-role" {
  capabilities = ["read"]
}

path "auth/token/renew-self" {
  capabilities = ["update"]
}

path "auth/token/lookup-self" {
  capabilities = ["read"]
}
EOF

# Read-only policy for PRs
vault policy write github-actions-readonly - <<EOF
path "aws/creds/deploy-role" {
  capabilities = ["read"]
}

path "auth/token/lookup-self" {
  capabilities = ["read"]
}
EOF
```

## Step 3: Update Project Configuration

### 3.1 Update Vault OIDC Variables ✅ COMPLETED
The file `modules/vault-oidc/variables.tf` has been updated with:
```hcl
variable "github_org" {
  description = "GitHub organization"
  type        = string
  default     = "kushal9897"  # ✅ Updated
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
  default     = "oidc"        # ✅ Updated
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"   # ✅ Set
}
```

### 3.2 Update Environment Variables
Edit `evviroments/qa/terraform.tfvars`:
```hcl
instance_type = "t3.micro"
aws_region    = "us-west-2"  # ← Change this
```

Edit `evviroments/data/terraform.tfvars`:
```hcl
instance_type = "t3.small"
aws_region    = "us-west-2"  # ← Change this
```

## Step 4: GitHub Repository Setup

### 4.1 Set Repository Secrets
Go to your GitHub repository → Settings → Secrets and variables → Actions

Add these **Repository Secrets**:
- `VAULT_ADDR`: `https://your-ngrok-url.ngrok.io` (use your ngrok HTTPS URL)

### 4.2 Enable GitHub Actions
1. Go to your repository
2. Click on "Actions" tab
3. Enable Actions if not already enabled

### 4.3 Configure OIDC (if needed)
GitHub Actions OIDC is enabled by default. No additional configuration needed.

## Step 5: Test the Setup

### 5.1 Test Vault Connectivity
```bash
# Test AWS credential generation
vault read aws/creds/deploy-role

# Test JWT auth (if you have a GitHub token)
vault write auth/jwt/login role=github-actions jwt=$GITHUB_TOKEN
```

### 5.2 Test GitHub Actions
1. Make a small change to any file in `evviroments/` folder
2. Commit and push to main branch
3. Check GitHub Actions tab for workflow execution

## Step 6: Terraform Backend (Optional)

If you want to use remote state, configure Terraform backend:

### 6.1 Create S3 Bucket for State
```bash
aws s3 mb s3://your-terraform-state-bucket-name
```

### 6.2 Update Backend Configuration
Add to `evviroments/qa/main.tf` and `evviroments/data/main.tf`:
```hcl
terraform {
  backend "s3" {
    bucket = "your-terraform-state-bucket-name"
    key    = "qa/terraform.tfstate"  # or "data/terraform.tfstate"
    region = "us-west-2"
  }
}
```

## Configuration Summary

Here's where you need to add your specific details:

| File/Location | What to Change | Example |
|---------------|----------------|---------|
| AWS IAM | Create user + policy | `vault-demo-user` |
| Vault Config | AWS credentials | Access Key + Secret |
| `modules/vault-oidc/variables.tf` | GitHub org/repo | `your-org/your-repo` |
| `evviroments/*/terraform.tfvars` | AWS region | `us-west-2` |
| GitHub Secrets | `VAULT_ADDR` | `https://abc123.ngrok.io` |
| Vault JWT Role | GitHub repo path | `repo:org/repo:ref:refs/heads/main` |

## Troubleshooting

### Common Issues

1. **Vault Authentication Fails**
   - Check `VAULT_ADDR` in GitHub secrets (must be ngrok HTTPS URL)
   - Verify JWT role configuration matches your repo
   - Ensure ngrok tunnel is still active

2. **ngrok Issues**
   - Tunnel expired: restart ngrok and update GitHub secret
   - Use HTTPS URL, not HTTP (GitHub Actions requires HTTPS)
   - Keep ngrok running during CI/CD operations

3. **AWS Credentials Error**
   - Ensure Vault AWS backend has correct credentials
   - Check IAM user has required permissions

4. **Terraform Init Fails**
   - Verify AWS credentials are working
   - Check Terraform backend configuration

5. **GitHub Actions Fails**
   - Check repository secrets are set with current ngrok URL
   - Verify OIDC token audience configuration
   - Ensure ngrok tunnel is active and accessible

### Debug Commands
```bash
# Check Vault status
vault status

# List auth methods
vault auth list

# List secrets engines
vault secrets list

# Test AWS credential generation
vault read aws/creds/deploy-role

# Check policies
vault policy list
vault policy read github-actions
```

## Next Steps

Once setup is complete:
1. Test by pushing changes to main branch
2. Verify both QA and Data environments deploy
3. Check Vault audit logs for authentication events
4. Practice your HashiConf demo!

## Security Notes

- Never commit AWS credentials to git
- Use short TTLs for Vault tokens (15 minutes)
- Regularly rotate the Vault AWS backend credentials
- Monitor Vault audit logs for suspicious activity
- Use least privilege AWS policies
