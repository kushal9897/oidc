# QA Environment Infrastructure

locals {
  environment = "qa"
  project     = "terraform-vault-demo"
  
  common_tags = {
    Environment = local.environment
    Project     = local.project
    ManagedBy   = "Terraform"
  }
}

# Get current AWS account info
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Get default VPC
data "aws_vpc" "default" {
  default = true
}

# Get default subnets
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Create security group
resource "aws_security_group" "qa" {
  name        = "${local.project}-${local.environment}-sg"
  description = "Security group for ${local.environment} environment"
  vpc_id      = data.aws_vpc.default.id
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access"
  }
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP access"
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }
  
  tags = merge(
    local.common_tags,
    {
      Name = "${local.project}-${local.environment}-sg"
    }
  )
}

# EC2 Instance
module "ec2" {
  source = "../../modules/ec2"
  
  name          = "${local.project}-${local.environment}-server"
  environment   = local.environment
  instance_type = var.instance_type
  
  subnet_id          = data.aws_subnets.default.ids[0]
  security_group_ids = [aws_security_group.qa.id]
  
  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    echo "<h1>QA Environment - ${local.project}</h1>" > /var/www/html/index.html
    echo "<p>Instance ID: $(ec2-metadata --instance-id | cut -d " " -f 2)</p>" >> /var/www/html/index.html
    echo "<p>Environment: ${local.environment}</p>" >> /var/www/html/index.html
  EOF
  
  tags = local.common_tags
}

# S3 Bucket
resource "aws_s3_bucket" "qa" {
  bucket = "${local.project}-${local.environment}-${data.aws_caller_identity.current.account_id}"
  
  tags = merge(
    local.common_tags,
    {
      Name = "${local.project}-${local.environment}-bucket"
    }
  )
}

# S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "qa" {
  bucket = aws_s3_bucket.qa.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "qa" {
  bucket = aws_s3_bucket.qa.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Bucket Public Access Block
resource "aws_s3_bucket_public_access_block" "qa" {
  bucket = aws_s3_bucket.qa.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Outputs
output "ec2_instance_id" {
  value = module.ec2.instance_id
}

output "ec2_public_ip" {
  value = module.ec2.public_ip
}

output "s3_bucket_name" {
  value = aws_s3_bucket.qa.id
}

output "web_url" {
  value = "http://${module.ec2.public_ip}"
}