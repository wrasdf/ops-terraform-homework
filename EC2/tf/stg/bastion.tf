module "bastion" {

  source              = "../modules/bastion"
  name                = "terraform-bastion"
  env                 = "${var.env}"

  vpc_id              = "${module.vpc.vpc_id}"
  vpc_zone_identifier = "${module.vpc.public_subnets}"
  region              = "${var.region}"
  amis                = "${var.amis}"
  bastion_ssh_key     = "${var.ssh_key}"

  tags = {
    Terraform = "true"
    Environment = "${var.env}"
  }

}
