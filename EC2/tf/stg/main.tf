terraform {
  backend "s3" {
    region = "ap-southeast-2"

    encrypt = true
    bucket = "terraform-tfstate-storage-stg"
    key = "ap-southeast-2-stage/terraform.tfstate"

  }
}

provider "aws" {
  version = ">= 1.46.0"
  region = "ap-southeast-2"
}
