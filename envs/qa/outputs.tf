output "instance_id" {
  description = "ID of the QA EC2 instance"
  value       = module.qa_instance.instance_id
}

output "public_ip" {
  description = "Public IP address of the QA instance"
  value       = module.qa_instance.public_ip
}

output "private_ip" {
  description = "Private IP address of the QA instance"
  value       = module.qa_instance.private_ip
}

output "security_group_id" {
  description = "ID of the QA instance security group"
  value       = module.qa_instance.sg_id
}
