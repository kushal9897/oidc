variable "name" {
  description = "Name for the EC2 instance and related resources"
  type        = string
}

variable "environment" {
  description = "Environment name (qa, backend, production)"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "ami_id" {
  description = "Specific AMI ID (optional - uses latest Amazon Linux 2 if not specified)"
  type        = string
  default     = ""
}

variable "root_volume_size" {
  description = "Size of root volume in GB"
  type        = number
  default     = 20
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}