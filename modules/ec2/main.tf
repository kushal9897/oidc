# EC2 Instance Resource
resource "aws_instance" "this" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = var.subnet_id
  
  vpc_security_group_ids = var.security_group_ids
  
  tags = merge(
    var.tags,
    {
      Name        = var.instance_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  )
  
  # Prevent accidental termination
  disable_api_termination = var.enable_termination_protection
  
  # Enable detailed monitoring
  monitoring = var.enable_monitoring
  
  # User data script for initial setup
  user_data = var.user_data
  
  # Instance metadata options for IMDSv2
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }
  
  root_block_device {
    volume_size = var.root_volume_size
    volume_type = var.root_volume_type
    encrypted   = true
    
    tags = merge(
      var.tags,
      {
        Name = "${var.instance_name}-root"
      }
    )
  }
}