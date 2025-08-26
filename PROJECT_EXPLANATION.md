# Project Architecture & Explanation

## 🎯 Project Overview

This project demonstrates **secure infrastructure provisioning** using HashiCorp Vault for dynamic AWS credential management with Terraform. It eliminates static credentials and implements namespace-based isolation across multiple environments.

## 🏗️ Architecture Components

### 1. **Vault Integration Layer**
```
Developer → Vault (ngrok) → AWS IAM → Terraform → EC2 Resources
```

**Purpose:** Centralized secrets management with dynamic credential generation
- **Vault Dev Server**: Local development instance exposed via ngrok
- **AWS Secrets Engine**: Generates temporary AWS credentials on-demand
- **IAM Roles**: Namespace-specific roles (qa-deploy, data-deploy, devops-deploy)
- **Short TTLs**: Credentials expire automatically (default: ~13 minutes)

### 2. **Terraform Module Structure**

#### **Reusable EC2 Module** (`modules/ec2-instance/`)
- **Purpose**: Standardized EC2 instance provisioning
- **Components**:
  - EC2 instance with latest Amazon Linux 2 AMI
  - Security group with HTTP/SSH access (demo configuration)
  - Automatic public IP assignment
  - Basic web server setup via user data

#### **Environment Roots** (`envs/{qa,data,devops}/`)
- **Purpose**: Environment-specific configurations
- **Features**:
  - Local state by default (S3 backend ready)
  - AWS provider configured for us-west-1
  - Module instantiation with environment-specific tags

### 3. **Automation Scripts**

#### **tf.sh** - Terraform Wrapper
```bash
./scripts/tf.sh <namespace> <plan|apply|destroy>
```
**Workflow:**
1. Validates environment and tools
2. Retrieves AWS credentials from Vault
3. Sets environment variables
4. Executes Terraform commands
5. Provides colored output and error handling

#### **demo-check.sh** - Environment Validator
**Checks:**
- Required CLI tools (vault, terraform, jq)
- Vault connectivity and authentication
- AWS secrets engine configuration
- Project structure integrity
- Terraform configuration validation

## 🔐 Security Architecture

### **Zero Static Credentials Pattern**
```
❌ Static AWS Keys in Code/Config
✅ Dynamic Credentials from Vault
```

**Benefits:**
- No credential storage in version control
- Automatic credential rotation
- Audit trail of credential usage
- Namespace isolation

### **IAM Policy Design**
Each namespace has minimal EC2 permissions:
```json
{
  "Effect": "Allow",
  "Action": [
    "ec2:RunInstances",
    "ec2:TerminateInstances",
    "ec2:DescribeInstances",
    "ec2:CreateSecurityGroup",
    "ec2:DeleteSecurityGroup"
  ],
  "Resource": "*",
  "Condition": {
    "StringEquals": {
      "aws:RequestedRegion": "us-west-1"
    }
  }
}
```

### **Vault Role Configuration**
```bash
vault write aws/roles/qa-deploy \
    credential_type=iam_user \
    policy_document=@policies/qa-iam.json
```

## 🚀 Workflow Explanation

### **Development Workflow**
1. **Setup Phase**:
   - Start Vault dev server
   - Expose via ngrok for external access
   - Configure AWS secrets engine
   - Create namespace-specific IAM roles

2. **Deployment Phase**:
   - Script retrieves fresh AWS credentials
   - Terraform authenticates to AWS
   - Infrastructure provisioned per namespace
   - Resources tagged for identification

3. **Cleanup Phase**:
   - Terraform destroys resources
   - AWS credentials automatically expire
   - No manual credential cleanup needed

### **Credential Lifecycle**
```
Request → Vault → AWS IAM → Temporary User → Terraform → Auto-Expire
```

**Timeline:**
- Credential generation: ~2 seconds
- Terraform operations: 2-5 minutes
- Credential expiration: ~13 minutes
- Safety buffer: 8+ minutes

## 📁 File Structure Explanation

### **Core Infrastructure**
```
modules/ec2-instance/
├── main.tf        # EC2 + Security Group resources
├── variables.tf   # Input parameters
└── outputs.tf     # Return values (IPs, IDs)
```

### **Environment Configurations**
```
envs/{namespace}/
├── main.tf        # Provider + Module instantiation
└── outputs.tf     # Environment-specific outputs
```

### **Security Policies**
```
policies/
├── qa-iam.json     # QA environment permissions
├── data-iam.json   # Data environment permissions
└── devops-iam.json # DevOps environment permissions
```

### **Automation**
```
scripts/
├── tf.sh          # Terraform wrapper with Vault integration
└── demo-check.sh  # Environment validation
```

## 🎛️ Configuration Management

### **Environment Variables**
```bash
VAULT_ADDR=https://abc123.ngrok-free.app  # Vault endpoint
VAULT_TOKEN=demo-root                     # Authentication
AWS_ACCESS_KEY_ID=AKIA...                 # Vault backend config
AWS_SECRET_ACCESS_KEY=xyz...              # Vault backend config
```

### **Terraform Variables**
- **instance_name**: Environment-specific naming
- **instance_type**: Resource sizing (default: t2.micro)
- **tags**: Resource identification and billing

### **Vault Configuration**
- **Secrets Engine**: AWS dynamic credentials
- **Roles**: Namespace-specific IAM policies
- **TTL**: Short-lived credential expiration

## 🔄 Production Considerations

### **State Management**
- **Development**: Local state files
- **Production**: S3 backend with DynamoDB locking
```hcl
backend "s3" {
  bucket         = "terraform-state-bucket"
  key            = "qa/terraform.tfstate"
  region         = "us-west-1"
  use_lockfile   = true
  dynamodb_table = "terraform-locks"
}
```

### **Security Hardening**
- Replace ngrok with private networking
- Implement proper Vault authentication
- Restrict security group rules
- Enable Vault audit logging
- Use least privilege IAM policies

### **Scalability**
- Add more namespaces by creating new environment folders
- Extend EC2 module for additional resource types
- Implement Terraform workspaces for environment variants
- Add CI/CD pipeline integration

## 🎯 Key Learning Points

### **1. Dynamic Secrets Management**
- Eliminates credential sprawl
- Provides audit trails
- Enables automatic rotation
- Reduces blast radius of compromised credentials

### **2. Infrastructure as Code**
- Consistent environment provisioning
- Version-controlled infrastructure changes
- Repeatable deployments
- Easy environment replication

### **3. Namespace Isolation**
- Separate IAM policies per environment
- Independent resource management
- Reduced cross-environment impact
- Clear responsibility boundaries

### **4. Automation & Validation**
- Automated credential retrieval
- Pre-flight environment checks
- Consistent deployment processes
- Error handling and recovery

This architecture demonstrates modern DevOps practices combining secrets management, infrastructure automation, and security best practices in a production-ready pattern.
