# OIDC Vault-Terraform Integration

A secure, automated infrastructure management system that leverages HashiCorp Vault for OIDC-based authentication and dynamic AWS credential management with Terraform automation across multiple environments, supporting both GitHub Actions and GitLab CI/CD pipelines.

## 🏗️ Architecture Overview

This project implements a secure DevOps pipeline that:
- Uses **HashiCorp Vault** as a centralized secrets management system
- Implements **OIDC authentication** for GitHub Actions and GitLab CI/CD
- Provides **dynamic AWS credentials** with short-lived tokens (15-30 minutes TTL)
- Automates **multi-environment deployments** (dev, qa, prod) using Terraform
- Ensures **zero-trust security** with JWT-based authentication

## 🚀 Features

- **Secure Authentication**: OIDC integration with GitHub Actions and GitLab CI
- **Dynamic Credentials**: Short-lived AWS credentials generated on-demand
- **Multi-Environment Support**: Separate namespaces for dev, qa, and production
- **Automated CI/CD**: GitHub Actions and GitLab pipelines with intelligent change detection
- **Infrastructure as Code**: Terraform modules for EC2, S3, and Vault configuration
- **Security Best Practices**: Token-based authentication, least privilege access

## 📁 Project Structure

```
oidc/
├── bootstrap/              # Initial Vault and AWS setup
│   ├── main.tf             # Vault providers, JWT auth backends, policies
│   └── variables.tf        # Configuration variables
├── modules/
│   ├── ec2/                # EC2 instance and S3 bucket module
│   └── vault-aws-auth/     # Vault AWS credential retrieval module
├── namespaces/             # Environment-specific configurations
│   ├── qa/                 # QA environment
│   ├── backend/            # Backend environment
│   └── prod/               # Production environment (referenced in CI/CD)
├── vault/
│   ├── config.hcl          # Vault server configuration
│   ├── policies/           # Vault access policies
│   └── setup.sh            # Vault initialization script
└── .gitlab-ci.yml          # CI/CD pipeline configuration
```

## 🛠️ Technologies Used

- **HashiCorp Vault** - Secrets management and OIDC authentication
- **Terraform** - Infrastructure as Code (IaC)
- **AWS** - Cloud infrastructure (EC2, S3, IAM)
- **GitLab CI/CD** - Automated deployment pipelines
- **OIDC/JWT** - Secure authentication protocol
- **Docker** - Containerized CI/CD environments

## 🔧 Setup Instructions

### Prerequisites

- HashiCorp Vault server running
- AWS account with appropriate permissions
- GitLab project configured
- Terraform >= 1.6.0

### 1. Initialize Vault

```bash
cd vault/
./setup.sh
```

### 2. Bootstrap Vault Configuration

```bash
cd bootstrap/
terraform init
terraform plan
terraform apply
```

### 3. Configure Environment Variables

Set the following variables in your CI/CD environments:

**For GitHub Actions:**
- `VAULT_ADDR` - Vault server URL
- `VAULT_NAMESPACE` - Vault namespace (admin)
- AWS credentials for initial bootstrap

**For GitLab CI/CD:**
- `VAULT_ADDR` - Vault server URL
- `VAULT_NAMESPACE` - Vault namespace (admin)
- AWS credentials for initial bootstrap

### 4. Deploy to Environments

**GitHub Actions Pipeline:**
- Triggers on pull requests and pushes
- Authenticates with Vault using OIDC JWT tokens
- Retrieves dynamic AWS credentials
- Applies Terraform configurations

**GitLab CI/CD Pipeline:**
- Detects changes in namespace directories
- Authenticates with Vault using OIDC
- Retrieves dynamic AWS credentials
- Applies Terraform configurations

## 🔐 Security Features

### OIDC Authentication
- **GitHub Actions**: JWT tokens for repository-specific access
- **GitLab CI**: JWT tokens with merge request validation
- **Bound Claims**: Restricts access to specific repositories and branches

### Dynamic AWS Credentials
- **Short TTL**: 15-minute default, 30-minute maximum
- **Least Privilege**: Role-based access with minimal required permissions
- **Automatic Rotation**: Credentials expire and regenerate automatically

### Vault Policies
- **Terraform Policy**: Read-only access to AWS credential paths
- **Token Management**: Self-renewal and child token creation
- **Audit Logging**: All access attempts logged and monitored

## 🚦 CI/CD Pipelines

### GitHub Actions Pipeline
1. **Trigger Events**: Pull requests and pushes to main branch
2. **OIDC Authentication**: JWT-based Vault authentication
3. **Terraform Validation**: Format checking and configuration validation
4. **Infrastructure Deployment**: Automated apply with approval workflows
5. **Multi-Environment Support**: Matrix builds for dev, qa, and prod

### GitLab CI/CD Pipeline
1. **Change Detection**: Only processes modified namespaces
2. **Vault Authentication**: OIDC-based secure login
3. **Terraform Validation**: Format checking and configuration validation
4. **Infrastructure Deployment**: Automated apply with approval workflows
5. **Multi-Environment Support**: Parallel deployments to dev, qa, and prod

## 📊 Monitoring & Observability

- **Vault Audit Logs**: Track all authentication and secret access
- **Terraform State**: Remote state management with locking
- **CI/CD Logs**: Detailed pipeline execution logs
- **AWS CloudTrail**: Infrastructure change tracking

## 🤝 Contributing

**For GitHub:**
1. Fork the repository
2. Create a feature branch
3. Make changes in the appropriate namespace directory
4. Submit a pull request to `main` branch
5. GitHub Actions will automatically validate and deploy changes

**For GitLab:**
1. Fork the repository
2. Create a feature branch
3. Make changes in the appropriate namespace directory
4. Submit a merge request to `main` branch
5. GitLab CI/CD will automatically validate and deploy changes

## 📝 Best Practices

- **Never commit secrets** to version control
- **Use short-lived credentials** for all AWS operations
- **Implement least privilege access** for all roles
- **Regularly rotate Vault tokens** and AWS credentials
- **Monitor audit logs** for suspicious activity

## 🔍 Troubleshooting

### Common Issues

1. **Vault Authentication Failed**
   - Verify `VAULT_ADDR` and JWT token configuration
   - Check bound claims in Vault role configuration

2. **Terraform Apply Failed**
   - Ensure AWS credentials have sufficient permissions
   - Verify Vault policy allows required operations

3. **Pipeline Skipped**
   - **GitHub**: Verify pull request targets the `main` branch and contains relevant changes
   - **GitLab**: Check if changes exist in the target namespace directory and merge request targets `main`

## 📞 Support

For issues and questions:
- Check the troubleshooting section
- Review Vault audit logs
- Contact the DevOps team

---

**Built with ❤️ for secure, automated infrastructure management**
