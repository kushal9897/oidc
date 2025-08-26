# 🚀 Project Startup Guide

## Step-by-Step Instructions to Run Your Vault CI/CD Demo

### Phase 1: Environment Setup (5 minutes)

#### 1. Start Vault Server
```bash
# Terminal 1: Start Vault in dev mode
vault server -dev -dev-root-token-id="myroot" -dev-listen-address="0.0.0.0:8200"
```

#### 2. Start ngrok Tunnel
```bash
# Terminal 2: Expose Vault to internet
ngrok http 8200
```
**📋 Copy the HTTPS URL** (e.g., `https://abc123.ngrok-free.app`)

#### 3. Set Environment Variables
```bash
# Terminal 3: Set these variables
export VAULT_ADDR="https://38fcdfa29518.ngrok-free.app"  # Use your actual ngrok URL
export VAULT_TOKEN="myroot"
export GITHUB_ORG="kushal9897"
export GITHUB_REPO="oidc"
export AWS_REGION="us-west-2"

# 🔑 IMPORTANT: Set your AWS credentials
export AWS_ACCESS_KEY_ID="AKIA4SDNWAAJN4U67NWH"      # Your AWS Access Key
export AWS_SECRET_ACCESS_KEY="FUDDK7a+J3YesQCoKscfw5lzIW1RxTexqjC9PCkU"      # Your AWS Secret Key
```

### Phase 2: Configure Vault (2 minutes)

#### 4. Run Setup Script
```bash
cd oidc/
./scripts/demo-setup.sh
```

**Expected Output:**
- ✅ Vault connection successful
- ✅ AWS secrets engine configured
- ✅ JWT auth method configured
- ✅ All policies created

### Phase 3: Configure GitHub (1 minute)

#### 5. Update GitHub Repository Secret
1. Go to: https://github.com/kushal9897/oidc/settings/secrets/actions
2. Update `VAULT_ADDR` with your current ngrok HTTPS URL
3. Click "Update secret"

### Phase 4: Test the Setup (2 minutes)

#### 6. Test Vault AWS Integration
```bash
# Test AWS credential generation
vault read aws/creds/deploy-role

# Should return something like:
# Key                Value
# ---                -----
# access_key         AKIA...
# secret_key         ...
# security_token     <nil>
```

#### 7. Test GitHub Actions Workflow
```bash
# Make a change to trigger the workflow
echo "# Test deployment $(date)" >> README.md
git add README.md
git commit -m "Test dynamic environment deployment"
git push origin main
```

#### 8. Verify Workflow Execution
1. Go to: https://github.com/kushal9897/oidc/actions
2. Check that "Vault CI/CD Pipeline" is running
3. Verify environments are detected and deployed

### Phase 5: Test Multiple Environments

#### 9. Test Different Environment Deployments
```bash
# Test QA environment
echo "# QA update" > evviroments/qa/test.txt
git add . && git commit -m "Update QA" && git push

# Test Data environment  
echo "# Data update" > evviroments/data/test.txt
git add . && git commit -m "Update Data" && git push

# Test any new environment (create folder first if needed)
mkdir -p evviroments/prod
echo "# Prod update" > evviroments/prod/test.txt
git add . && git commit -m "Update Prod" && git push
```

### Phase 6: Monitor & Debug

#### 10. Check Vault Audit Logs
```bash
# View audit logs
tail -f /tmp/vault-audit/audit.log | jq '.'
```

#### 11. Debug Common Issues

**Issue: "Invalid security token"**
```bash
# Check AWS credentials in Vault
vault read aws/config/root

# Reconfigure if needed
vault write aws/config/root \
    access_key=$AWS_ACCESS_KEY_ID \
    secret_key=$AWS_SECRET_ACCESS_KEY \
    region=us-west-2
```

**Issue: "JWT authentication failed"**
```bash
# Check JWT configuration
vault read auth/jwt/config
vault read auth/jwt/role/github-actions
```

**Issue: "ngrok tunnel not accessible"**
```bash
# Restart ngrok and update GitHub secret
ngrok http 8200
# Copy new URL to GitHub secrets
```

### Phase 7: Demo Scenarios

#### 12. Prepare Demo Scenarios

**Scenario A: Multi-Environment Deployment**
```bash
# Change multiple environments at once
echo "update" > evviroments/qa/demo.txt
echo "update" > evviroments/data/demo.txt
git add . && git commit -m "Multi-env deployment" && git push
```

**Scenario B: Pull Request (Read-Only)**
```bash
# Create PR branch
git checkout -b demo-pr
echo "PR change" > evviroments/qa/pr-test.txt
git add . && git commit -m "PR test"
git push origin demo-pr
# Create PR on GitHub - should only run terraform plan
```

**Scenario C: Module Changes (Deploy All)**
```bash
# Change module - should trigger all environments
echo "# Module update" > modules/ec2/main.tf
git add . && git commit -m "Module update" && git push
```

### Quick Reference Commands

```bash
# Check Vault status
vault status

# List AWS roles
vault list aws/roles

# Test AWS credential generation
vault read aws/creds/deploy-role

# Check GitHub Actions
curl -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/kushal9897/oidc/actions/runs

# View ngrok status
curl http://127.0.0.1:4040/api/tunnels
```

### Troubleshooting Checklist

- [ ] Vault server running on port 8200
- [ ] ngrok tunnel active and HTTPS URL copied
- [ ] Environment variables set (especially AWS credentials)
- [ ] GitHub secret `VAULT_ADDR` updated with current ngrok URL
- [ ] AWS credentials valid and have required permissions
- [ ] Setup script completed successfully

### Emergency Reset

If everything breaks:
```bash
# 1. Stop all processes
pkill vault
pkill ngrok

# 2. Restart fresh
vault server -dev -dev-root-token-id="myroot" -dev-listen-address="0.0.0.0:8200"
ngrok http 8200

# 3. Re-run setup
export VAULT_ADDR="https://new-ngrok-url.ngrok-free.app"
export VAULT_TOKEN="myroot"
# ... set other variables
./scripts/demo-setup.sh

# 4. Update GitHub secret with new ngrok URL
```

## 🎯 You're Ready!

Your Vault CI/CD demo is now fully functional with:
- ✅ Dynamic environment detection (supports 50+ environments)
- ✅ Vault OIDC authentication 
- ✅ AWS credential management via Vault
- ✅ Matrix-based deployment strategy
- ✅ Audit logging and monitoring

**Demo Time:** ~10 minutes total setup, ready for HashiConf presentation!
