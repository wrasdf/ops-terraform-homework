module "bastion" {

  source            = "../modules/bastion"
  name              = "terraform-bastion"

  vpc_id            = "${module.vpc.vpc_id}"
  azs               = "${module.vpc.azs}"
  region            = "${var.region}"
  amis              = "${var.amis}"
  bastion_ssh_key   = "${var.ssh_key}"

  tags = {
    Terraform   = "true"
    Environment = "${var.env}"
  }

}
