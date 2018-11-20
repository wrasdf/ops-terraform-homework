variable "name" {
  description = "Terraform bastion stack name"
  default     = ""
}

variable "bastion_ami_id" {
  description = "Bastion AMI Id"
  default     = ""
}

variable "bastion_ssh_key" {
  description = "SSHkey name for the bastion box"
  default     = "EC2-Key"
}

variable "bastion_instance_type" {
  description = "Instance type for bastion ec2 box"
  default     = "t2.nano"
}

variable "tags" {
  description = "A map of tags to add to all resources"
  default     = {}
}
