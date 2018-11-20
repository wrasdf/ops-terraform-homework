terraform {
  required_version = ">= 0.11.10" # introduction of Local Values configuration language feature
}

locals {
  vpc_id = "${element(concat(aws_vpc.main.*.id, list("")), 0)}"
}

######
# VPC
######
resource "aws_vpc" "main" {
  cidr_block                       = "${var.cidr}"
  enable_dns_hostnames             = "false"
  enable_dns_support               = "false"

  tags = "${merge("${var.tags}", map("Name", "${var.name}-vpc"))}"
}

###################
# DHCP
###################
resource "aws_vpc_dhcp_options" "vpc_dhcp" {
  domain_name          = "ops.terraform.homework"
  domain_name_servers  = ["8.8.8.8"]

  tags = "${merge("${var.tags}", map("Name", "${var.name}-dhcp"))}"
}

resource "aws_vpc_dhcp_options_association" "vpc_dhcp_association" {
  vpc_id          = "${local.vpc_id}"
  dhcp_options_id = "${aws_vpc_dhcp_options.vpc_dhcp.id}"
}

###################
# Internet Gateway
###################
resource "aws_internet_gateway" "gw" {
  vpc_id = "${local.vpc_id}"

  tags = "${merge("${var.tags}", map("Name", "${var.name}-internet-gateway"))}"
}

################
# Publiс subnets
################

resource "aws_subnet" "public_subnets" {
  count = "${length(var.public_subnets)}"
  vpc_id = "${local.vpc_id}"
  availability_zone = "${element(var.azs, count.index)}"
  cidr_block = "${element(var.public_subnets, count.index)}"
  map_public_ip_on_launch = true

  tags = "${merge("${var.tags}", map("Name", "${var.name}-${element(var.azs, count.index)}"))}"
}

resource "aws_route_table" "public_route_tables" {
  depends_on = ["aws_internet_gateway.gw"]

  count = "${length(var.public_subnets)}"
  vpc_id = "${local.vpc_id}"

  tags = "${merge("${var.tags}", map("Name", "${var.name}-routetable-${element(var.azs, count.index)}"))}"
}

resource "aws_route" "public_route" {
  count = "${length(var.public_subnets)}"
  route_table_id         = "${element(aws_route_table.public_route_tables.*.id, count.index)}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.gw.id}"

  timeouts {
    create = "5m"
  }
}

resource "aws_route_table_association" "public_route_tables_association" {
  count = "${length(var.public_subnets)}"
  subnet_id      = "${element(aws_subnet.public_subnets.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.public_route_tables.*.id, count.index)}"
}
