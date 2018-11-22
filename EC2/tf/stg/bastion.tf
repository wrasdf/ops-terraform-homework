module "bastion" {

  source          = "../modules/bastion"
  
  name            = "terraform-bastion"
  bastion_ami_id  = "ami-0d4d4a42a45fb8e4a"
  bastion_ssh_key = "EC2-Key"

  tags = {
    Terraform   = "true"
    Environment = "stg"
  }

}
