# Vault CI/CD Integration Demo

Simple HashiCorp Vault integration with GitHub Actions for your HashiConf talk.

## What This Does

- Uses GitHub OIDC to authenticate to Vault (no stored secrets!)
- Gets dynamic AWS credentials from Vault
- Deploys to QA and Data environments using Terraform
- Automatically cleans up credentials after use

## Quick Setup

### 1. Configure Vault
```bash
# Run the setup script
./scripts/demo-setup.sh
```

### 2. Set GitHub Repository Secrets
- `VAULT_ADDR`: Your Vault server URL

### 3. Update Configuration
Edit these files with your details:
- `modules/vault-oidc/variables.tf` - Set your GitHub org/repo
- `evviroments/*/terraform.tfvars` - Set your AWS region

## How It Works

1. **Push to main** → Deploys to both environments
2. **Pull request** → Plans only (read-only access)
3. **No manual secrets** → Everything uses OIDC + Vault

## Project Structure

```
├── .github/workflows/terraform-deploy.yml  # CI/CD pipeline
├── evviroments/
│   ├── qa/          # QA environment
│   └── data/        # Data environment  
├── modules/vault-oidc/  # Vault configuration
└── scripts/demo-setup.sh  # Setup script
```

## For Your Demo

The pipeline shows:
- OIDC authentication (no long-lived secrets)
- Dynamic credential generation
- Multi-environment deployment
- Automatic cleanup

Perfect for demonstrating Vault CI/CD best practices!
