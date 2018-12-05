variable "name" {
  description = "Terraform bastion stack name"
  default     = ""
}

variable "region" {
  description = "Current stack region"
}

variable "amis" {
  type = "map"
  description = "AMI Ids"
}


variable "vpc_id" {
  description = "Bastion vpc id"
  default     = ""
}

variable "azs" {
  description = "vpc zone identifier"
  default     = []
}

variable "bastion_ssh_key" {
  description = "SSHkey name for the bastion box"
}

variable "bastion_instance_type" {
  description = "Instance type for bastion ec2 box"
  default     = "t2.nano"
}

variable "tags" {
  description = "A map of tags to add to all resources"
  default     = {}
}
