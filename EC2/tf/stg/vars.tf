variable "env" { default = "stg" }
variable "region" { default = "ap-southeast-1" }
variable "s3-bucket" { default = "terraform-tfstate-storage-stg" }
variable "ssh_key" { default = "EC2-Key" }

variable "amis" {
  type = "map"
  default = {
    "ap-southeast-1" = "ami-0b84d2c53ad5250c2"
    "ap-southeast-2" = "ami-08c26730c8ee004fa"
  }
}
