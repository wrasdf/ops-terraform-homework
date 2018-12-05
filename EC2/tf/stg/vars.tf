# region
variable "region" { default = "ap-southeast-1" }
variable "env" { default = "stg" }
variable "s3-bucket" { default = "terraform-tfstate-storage-stg" }
variable "ssh_key" { default = "EC2-Key" }
variable "bastion_ami_id" { default = "ami-0b84d2c53ad5250c2" }
