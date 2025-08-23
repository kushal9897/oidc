# Backend Environment Infrastructure

locals {
  environment = "backend"
  common_tags = {
    Environment = local.environment
    Project     = "vault-ci-demo"
    ManagedBy   = "Terraform"
    Owner       = "DevOps"
  }
}

# EC2 Instance using our module
module "ec2_instance" {
  source = "../../modules/ec2"
  
  instance_name              = "${local.environment}-demo-instance"
  ami_id                    = var.ami_id
  instance_type             = var.instance_type
  subnet_id                 = var.subnet_id
  security_group_ids        = var.security_group_ids
  environment               = local.environment
  enable_monitoring         = true
  enable_termination_protection = true  # More protection for backend
  
  user_data = <<-EOF
    #!/bin/bash
    echo "Backend Environment Instance" > /tmp/environment.txt
    yum update -y || apt-get update -y
  EOF
  
  tags = local.common_tags
}

# S3 Bucket for Backend environment
resource "aws_s3_bucket" "backend_bucket" {
  bucket = "${local.environment}-demo-bucket-${data.aws_caller_identity.current.account_id}"
  
  tags = merge(
    local.common_tags,
    {
      Name = "${local.environment}-demo-bucket"
    }
  )
}

# S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "backend_bucket_versioning" {
  bucket = aws_s3_bucket.backend_bucket.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "backend_bucket_encryption" {
  bucket = aws_s3_bucket.backend_bucket.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Bucket Public Access Block
resource "aws_s3_bucket_public_access_block" "backend_bucket_pab" {
  bucket = aws_s3_bucket.backend_bucket.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Bucket Lifecycle Rules for Backend
resource "aws_s3_bucket_lifecycle_configuration" "backend_bucket_lifecycle" {
  bucket = aws_s3_bucket.backend_bucket.id
  
  rule {
    id     = "archive-old-objects"
    status = "Enabled"
    
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
    
    transition {
      days          = 90
      storage_class = "GLACIER"
    }
  }
}

# Data source for current AWS account
data "aws_caller_identity" "current" {}

# Outputs
output "ec2_instance_id" {
  value = module.ec2_instance.instance_id
}

output "ec2_private_ip" {
  value = module.ec2_instance.private_ip
}

output "s3_bucket_name" {
  value = aws_s3_bucket.backend_bucket.id
}

output "s3_bucket_arn" {
  value = aws_s3_bucket.backend_bucket.arn
}