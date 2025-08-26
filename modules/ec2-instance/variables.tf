variable "instance_name" {
  description = "Name for the EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "vpc_id" {
  description = "VPC ID to deploy the instance in (optional, uses default VPC if not provided)"
  type        = string
  default     = null
}

variable "subnet_id" {
  description = "Subnet ID to deploy the instance in (optional, uses default subnet if not provided)"
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
