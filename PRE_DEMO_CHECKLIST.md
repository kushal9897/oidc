# Pre-Demo Startup Checklist

## 🚀 Complete Setup & Testing Guide

### Phase 1: Environment Setup (30 minutes before demo)

#### 1. Start Vault & ngrok
```bash
# Terminal 1: Start Vault
vault server -dev -dev-root-token-id="myroot" -dev-listen-address="0.0.0.0:8200"

# Terminal 2: Start ngrok
ngrok http 8200
# Copy the HTTPS URL (e.g., https://abc123.ngrok.io)
```

#### 2. Set Environment Variables
```bash
export VAULT_ADDR="https://your-ngrok-url.ngrok.io"  # Use actual ngrok URL
export VAULT_TOKEN="myroot"
export GITHUB_ORG="kushal9897"
export GITHUB_REPO="oidc"
export AWS_REGION="us-west-2"
export AWS_ACCESS_KEY_ID="your-aws-key"
export AWS_SECRET_ACCESS_KEY="your-aws-secret"
```

#### 3. Run Setup Script
```bash
./scripts/demo-setup.sh
```

#### 4. Update GitHub Repository Secret
- Go to: https://github.com/kushal9897/oidc/settings/secrets/actions
- Update `VAULT_ADDR` with current ngrok URL

### Phase 2: Project Configuration

#### 1. Files Already Updated ✅
- `modules/vault-oidc/variables.tf` → GitHub org/repo set to kushal9897/oidc
- `scripts/demo-setup.sh` → GitHub org/repo set to kushal9897/oidc

#### 2. Files You Need to Check/Update

**Environment Variables:**
- `evviroments/qa/terraform.tfvars`
- `evviroments/data/terraform.tfvars`

**GitHub Workflow:**
- `.github/workflows/terraform-deploy.yml` → Check VAULT_ADDR reference

### Phase 3: Testing (15 minutes before demo)

#### 1. Test Vault Setup
```bash
# Test AWS credential generation
vault read aws/creds/deploy-role

# Test JWT auth (if you have GitHub token)
vault write auth/jwt/login role=github-actions jwt=$GITHUB_TOKEN

# Check policies
vault policy list
vault policy read github-actions
```

#### 2. Test GitHub Actions
```bash
# Make a small change to trigger workflow
echo "# Demo ready $(date)" >> README.md
git add README.md
git commit -m "Test workflow before demo"
git push origin main
```

#### 3. Verify Workflow Execution
- Go to: https://github.com/kushal9897/oidc/actions
- Check that workflow runs successfully
- Verify both QA and Data environments deploy

### Phase 4: Demo Preparation

#### 1. Prepare Demo Scenarios
- **Scenario 1:** Push to main → Both environments deploy
- **Scenario 2:** Create PR → Read-only access, terraform plan only
- **Scenario 3:** Show Vault audit logs
- **Scenario 4:** Demonstrate secret rotation

#### 2. Have Backup Plans
- Keep ngrok running throughout demo
- Have screenshots ready if live demo fails
- Prepare to show Vault UI and GitHub Actions logs

### Phase 5: Common Issues & Solutions

#### Issue: JWT Role Creation Fails
**Error:** `expected a map, got 'string'`
**Solution:** Script now uses `bound_claims=@-` with heredoc JSON

#### Issue: ngrok Tunnel Expires
**Solution:** 
```bash
# Restart ngrok
ngrok http 8200
# Update GitHub secret with new URL
```

#### Issue: AWS Credentials Not Working
**Solution:**
```bash
# Reconfigure AWS backend
vault write aws/config/root \
    access_key=$AWS_ACCESS_KEY_ID \
    secret_key=$AWS_SECRET_ACCESS_KEY \
    region=us-west-2
```

#### Issue: GitHub Actions Can't Reach Vault
**Check:**
- ngrok tunnel is active
- GitHub secret has correct HTTPS URL
- Vault is accessible from internet

### Phase 6: Demo Script Points

#### 1. Introduction (2 minutes)
- Show the problem: Hardcoded secrets in CI/CD
- Introduce Vault + OIDC solution

#### 2. Architecture Overview (3 minutes)
- GitHub Actions → Vault OIDC → AWS Dynamic Credentials
- Show different environments (QA vs Data)
- Explain workload identity benefits

#### 3. Live Demo (8 minutes)
- Push to main branch
- Show GitHub Actions workflow
- Demonstrate Vault credential generation
- Show audit logs
- Create PR to show read-only access

#### 4. Best Practices & Pitfalls (5 minutes)
- Token TTL management
- Environment isolation
- Secret sprawl prevention
- Common misconfigurations

#### 5. Q&A (7 minutes)
- Be ready for questions about:
  - Token rotation
  - Multi-cloud scenarios
  - Enterprise features
  - Migration strategies

### Emergency Contacts & Resources

- **Vault Documentation:** https://developer.hashicorp.com/vault
- **GitHub OIDC:** https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect
- **Demo Repository:** https://github.com/kushal9897/oidc

### Final Checklist ✅

- [ ] Vault running with ngrok
- [ ] GitHub secret updated with current ngrok URL
- [ ] Demo script executed successfully
- [ ] Test workflow completed
- [ ] Backup slides ready
- [ ] Demo scenarios practiced
- [ ] Questions prepared for Q&A

**Remember:** Keep ngrok running throughout the entire demo!
