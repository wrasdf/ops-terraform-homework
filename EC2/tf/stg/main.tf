terraform {
  backend "s3" {
    region  = "ap-southeast-1"
    encrypt = true
    bucket  = "terraform-tfstate-storage-stg"
    key     = "ap-southeast-1-stg/terraform.tfstate"
    # region  = "${var.region}"
    # bucket  = "${var.s3-bucket}"
    # key     = "${var.region}-${var.env}/terraform.tfstate"
  }
}

provider "aws" {
  version = ">= 1.46.0"
  region  = "${var.region}"
}
