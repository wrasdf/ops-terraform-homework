variable "name" {
  description = "Terraform app stack name"
  default     = ""
}

variable "app_ami_id" {
  description = "Bastion AMI Id"
  default     = ""
}

variable "app_ssh_key" {
  description = "SSHkey name for the bastion box"
  default     = "EC2-Key"
}

variable "app_instance_type" {
  description = "Instance type for bastion ec2 box"
  default     = ""
}

variable "tags" {
  description = "A map of tags to add to all resources"
  default     = {}
}
