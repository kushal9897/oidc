# QA Environment Configuration
# This automatically gets AWS credentials from Vault

locals {
  environment = "qa"
  project     = "vault-terraform-demo"
  
  common_tags = {
    Environment = local.environment
    Project     = local.project
    Namespace   = "qa"
    ManagedBy   = "Terraform"
  }
}

# Get AWS credentials from Vault
module "vault_aws" {
  source = "../../modules/vault-aws-auth"
  
  vault_backend_path = "aws"
  vault_role_name    = "terraform-role"
  credential_type    = "sts"
  ttl                = 900  # 15 minutes
}

# Create EC2 instance and S3 bucket
module "ec2_instance" {
  source = "../../modules/ec2"
  
  name          = "test"
  environment   = local.environment
  instance_type = var.instance_type
  
  tags = local.common_tags
}

# Outputs
output "instance_id" {
  value = module.ec2_instance.instance_id
}

output "public_ip" {
  value = module.ec2_instance.public_ip
}

output "s3_bucket" {
  value = module.ec2_instance.s3_bucket_name
}

output "access_url" {
  value = module.ec2_instance.instance_url
}

output "aws_credentials_lease_id" {
  value     = module.vault_aws.lease_id
  sensitive = true
}

output "credentials_expire_in" {
  value = "${module.vault_aws.lease_duration} seconds"
}