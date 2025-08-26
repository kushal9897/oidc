output "instance_id" {
  description = "ID of the Data EC2 instance"
  value       = module.data_instance.instance_id
}

output "public_ip" {
  description = "Public IP address of the Data instance"
  value       = module.data_instance.public_ip
}

output "private_ip" {
  description = "Private IP address of the Data instance"
  value       = module.data_instance.private_ip
}

output "security_group_id" {
  description = "ID of the Data instance security group"
  value       = module.data_instance.sg_id
}
