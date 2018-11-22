module "app" {

  source            = "../modules/app"

  name              = "terraform-app"
  app_ami_id        = "ami-0d4d4a42a45fb8e4a"
  app_ssh_key       = "EC2-Key"
  app_instance_type = "t2.medium"

  tags = {
    Terraform = "true"
    Environment = "stg"
  }

}
