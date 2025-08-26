output "instance_id" {
  description = "ID of the DevOps EC2 instance"
  value       = module.devops_instance.instance_id
}

output "public_ip" {
  description = "Public IP address of the DevOps instance"
  value       = module.devops_instance.public_ip
}

output "private_ip" {
  description = "Private IP address of the DevOps instance"
  value       = module.devops_instance.private_ip
}

output "security_group_id" {
  description = "ID of the DevOps instance security group"
  value       = module.devops_instance.sg_id
}
