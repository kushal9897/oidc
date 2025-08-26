# 🎪 HashiConf 2025 Demo Script
## "Integrating Vault with CI/CD pipelines: Best practices and pitfalls"

**Duration:** 30 minutes  
**Level:** 200 (Intermediate to Advanced)  
**Date:** September 25, 2025 | 2:00 PM PT - 2:30 PM PT

---

## 🎯 Session Objectives
By the end of this session, attendees will understand:
- How to securely integrate Vault with CI/CD pipelines
- OIDC workload identity patterns
- Common security pitfalls and prevention strategies
- Enterprise-grade secret management practices

---

## 📋 Pre-Demo Checklist
- [ ] Vault cluster running and accessible
- [ ] GitHub repository with demo code ready
- [ ] AWS account configured
- [ ] Demo environments clean
- [ ] Backup slides prepared
- [ ] Network connectivity tested

---

## 🎬 Demo Flow

### Opening Hook (2 minutes)
> "How many of you have AWS access keys sitting in your CI/CD systems right now? Keep your hands up if they're older than 90 days... 6 months... a year?"

**Key Message:** Traditional CI/CD security is broken. Let's fix it.

---

### Part 1: The Problem - Traditional CI/CD Security (5 minutes)

#### 1.1 Show the "Bad" Example
```bash
# Traditional approach - DON'T DO THIS
export AWS_ACCESS_KEY_ID="AKIA..."  # Long-lived credential
export AWS_SECRET_ACCESS_KEY="..."   # Stored in CI/CD system
```

**Talk Track:**
- "This is how most organizations handle secrets today"
- "These credentials are often long-lived, shared, and stored insecurely"
- "When compromised, blast radius is huge"

#### 1.2 Common Problems Demo
```bash
# Show hardcoded secrets in code
grep -r "AKIA" . --exclude-dir=.git

# Show secret sprawl
echo "Secrets in:"
echo "- CI/CD variables"
echo "- Configuration files"
echo "- Container images"
echo "- Developer machines"
```

**Key Points:**
- Secret sprawl across multiple systems
- No rotation or expiration
- Difficult to audit and revoke
- Compliance nightmares

---

### Part 2: The Solution - Vault + OIDC (15 minutes)

#### 2.1 OIDC Workload Identity (5 minutes)

**Talk Track:** "Instead of storing secrets, let's use identity"

```bash
# Show GitHub OIDC token
echo "GitHub provides us with a JWT token that proves our identity"
echo $ACTIONS_ID_TOKEN_REQUEST_TOKEN | head -c 50

# Decode the JWT to show claims
GITHUB_TOKEN=$(curl -H "Authorization: bearer $ACTIONS_ID_TOKEN_REQUEST_TOKEN" \
  "$ACTIONS_ID_TOKEN_REQUEST_URL&audience=vault" | jq -r '.value')

echo $GITHUB_TOKEN | cut -d. -f2 | base64 -d | jq .
```

**Show on screen:**
```json
{
  "sub": "repo:myorg/myrepo:ref:refs/heads/main",
  "aud": "vault",
  "repository": "myorg/myrepo",
  "actor": "platform-engineer",
  "workflow": "terraform-deploy"
}
```

**Key Points:**
- No secrets to store or manage
- Cryptographically signed by GitHub
- Contains rich context about the request
- Short-lived (15 minutes)

#### 2.2 Vault Authentication (3 minutes)

```bash
# Authenticate to Vault using JWT
vault write auth/jwt/login \
  role=github-actions \
  jwt=$GITHUB_TOKEN

# Show the response
echo "✅ Vault token received with 15-minute TTL"
```

**Talk Track:**
- "Vault validates the JWT signature"
- "Checks bound claims (repo, branch, etc.)"
- "Issues short-lived Vault token"
- "No long-lived secrets anywhere"

#### 2.3 Dynamic AWS Credentials (4 minutes)

```bash
# Request dynamic AWS credentials
echo "🔄 Requesting dynamic AWS credentials..."
vault read aws/creds/deploy-role

# Show the credentials
echo "✅ Fresh AWS credentials generated"
echo "🕒 TTL: 15 minutes"
echo "🔐 Unique to this workflow run"
```

**Demo the infrastructure deployment:**
```bash
# Use the dynamic credentials
terraform plan
terraform apply -auto-approve
```

**Key Points:**
- Credentials generated on-demand
- Unique per request
- Automatic expiration
- Least privilege permissions

#### 2.4 Multi-Environment Security (3 minutes)

**Show different security levels:**

```bash
# QA Environment
echo "QA Environment:"
echo "- Role: github-actions"
echo "- TTL: 15 minutes"
echo "- Permissions: Full EC2/S3"

# Data Environment (Production-like)
echo "Data Environment:"
echo "- Role: github-actions-data"
echo "- TTL: 10 minutes"
echo "- Permissions: Restricted with explicit denies"
echo "- Requires approval"
```

**Show the GitHub workflow:**
- Environment protection rules
- Different Vault roles
- Enhanced audit logging

---

### Part 3: Best Practices & Pitfall Prevention (6 minutes)

#### 3.1 Common Pitfalls (3 minutes)

**Pitfall 1: Token Reuse**
```bash
# BAD: Storing and reusing tokens
export VAULT_TOKEN="hvs.abc123"  # DON'T DO THIS

# GOOD: Fresh token per job, automatic cleanup
echo "Each job gets fresh credentials"
echo "Automatic lease revocation in cleanup"
```

**Pitfall 2: Secret Sprawl**
```bash
# Show centralized secret management
echo "All secrets managed in Vault:"
echo "- Database credentials"
echo "- API keys"
echo "- Certificates"
echo "- Cloud provider credentials"
```

**Pitfall 3: Environment Leakage**
```bash
# Show bound claims preventing cross-environment access
vault read auth/jwt/role/github-actions-data
echo "Bound claims prevent QA role from accessing Data environment"
```

#### 3.2 Security Controls Demo (3 minutes)

**Show the security pipeline:**
```bash
# Pre-deployment security scan
echo "🔍 Security scanning:"
echo "- Hardcoded secret detection"
echo "- Terraform validation"
echo "- Policy compliance"

# Runtime security
echo "🛡️ Runtime security:"
echo "- JWT claim validation"
echo "- Lease tracking"
echo "- Automatic cleanup"
echo "- Audit logging"
```

**Show audit logs:**
```bash
# Vault audit log
tail -f /vault/logs/audit.log | jq 'select(.request.path | contains("aws/creds"))'
```

---

### Part 4: Enterprise Patterns (2 minutes)

#### 4.1 Scaling Considerations
```bash
echo "Enterprise patterns:"
echo "- Vault namespaces for team isolation"
echo "- Policy templating"
echo "- Automated policy updates"
echo "- Cross-region replication"
```

#### 4.2 Compliance & Governance
```bash
echo "Compliance features:"
echo "- Complete audit trail"
echo "- Policy-as-code"
echo "- Automated compliance reporting"
echo "- Integration with SIEM systems"
```

---

## 🎯 Key Takeaways

### ✅ Do This
1. **Use OIDC workload identity** instead of long-lived secrets
2. **Implement short TTLs** (15 minutes or less)
3. **Use environment-specific roles** with least privilege
4. **Automate credential cleanup** in your pipelines
5. **Monitor and audit** all secret access

### ❌ Avoid This
1. **Don't store Vault tokens** in CI/CD systems
2. **Don't reuse credentials** across jobs
3. **Don't use overly broad permissions**
4. **Don't skip security scanning**
5. **Don't ignore audit logs**

---

## 🔧 Demo Recovery

### If Vault is Down
- Switch to slides showing architecture
- Walk through code examples
- Use pre-recorded demo video

### If GitHub Actions Fails
- Show local Vault CLI examples
- Demonstrate concepts with curl commands
- Focus on security patterns discussion

### If AWS Issues
- Use mock responses
- Focus on Vault concepts
- Show policy examples

---

## 📊 Audience Engagement

### Polls
1. "How many environments do you deploy to?"
2. "What's your biggest secret management challenge?"
3. "Do you currently use dynamic credentials?"

### Q&A Preparation
**Common Questions:**
- "How do you handle Vault high availability?"
- "What about secret rotation?"
- "How do you manage Vault policies at scale?"
- "What's the performance impact?"

---

## 🎬 Closing (30 seconds)

> "Security doesn't have to be complicated. With Vault and OIDC, you can eliminate long-lived secrets, reduce your attack surface, and sleep better at night. The patterns we've shown today are battle-tested in production environments processing billions of requests."

**Call to Action:**
- "Try the demo repository"
- "Join the Vault community"
- "Questions? Find me after the session"

---

## 📱 Contact & Resources

- **Demo Repository:** github.com/yourorg/vault-cicd-demo
- **Vault Documentation:** vaultproject.io/docs
- **Community:** discuss.hashicorp.com
- **Twitter:** @yourhandle

---

*Remember: Practice makes perfect. Run through this demo at least 3 times before the presentation!*
