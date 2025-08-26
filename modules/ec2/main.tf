# EC2 Instance Module
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Get latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
  
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# EC2 Instance
resource "aws_instance" "this" {
  ami           = var.ami_id != "" ? var.ami_id : data.aws_ami.amazon_linux_2.id
  instance_type = var.instance_type
  
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.security_group_ids
  
  user_data = var.user_data
  
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }
  
  root_block_device {
    volume_size = var.root_volume_size
    volume_type = "gp3"
    encrypted   = true
    
    tags = merge(
      var.tags,
      {
        Name = "${var.name}-root-volume"
      }
    )
  }
  
  tags = merge(
    var.tags,
    {
      Name        = var.name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  )
  
  lifecycle {
    create_before_destroy = true
  }
}