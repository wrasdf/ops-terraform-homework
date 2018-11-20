provider "aws" {
  version = ">= 1.46.0"
  region = "ap-southeast-1"
}

module "vpc" {

  source = "../modules/vpc"

  name = "terraform-net"
  cidr = "10.10.0.0/16"

  azs                 = ["ap-southeast-1a", "ap-southeast-1b", "ap-southeast-1c"]
  public_subnets      = ["10.10.11.0/24", "10.10.12.0/24", "10.10.13.0/24"]
  private_subnets     = ["10.10.1.0/24", "10.10.2.0/24", "10.10.3.0/24"]
  database_subnets    = ["10.10.21.0/24", "10.10.22.0/24", "10.10.23.0/24"]

  tags = {
    Terraform = "true"
    Environment = "stg"
  }

}
