terraform {
  required_version = ">= 0.11.10" # introduction of Local Values configuration language feature
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

######
# VPC Flow Log
######
resource "aws_cloudwatch_log_group" "vpc" {
  name = "${var.name}-flow-logs"
  retention_in_days = 14
}

resource "aws_flow_log" "vpc" {
  iam_role_arn    = "${aws_iam_role.vpc.arn}"
  log_destination = "${aws_cloudwatch_log_group.vpc.arn}"
  traffic_type    = "ALL"
  vpc_id          = "${aws_vpc.main.id}"
}

resource "aws_iam_role" "vpc" {
  name = "${var.name}-flow-log-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "vpc-flow-logs.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "vpc" {
  name = "allowvpclogs"
  role = "${aws_iam_role.vpc.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
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
  vpc_id          = "${aws_vpc.main.id}"
  dhcp_options_id = "${aws_vpc_dhcp_options.vpc_dhcp.id}"
}

###################
# Internet Gateway
###################
resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.main.id}"

  tags = "${merge("${var.tags}", map("Name", "${var.name}-internet-gateway"))}"
}

################
# Publiс subnets
################

resource "aws_subnet" "public_subnets" {
  count = "${length(var.public_subnets)}"
  vpc_id = "${aws_vpc.main.id}"
  availability_zone = "${element(var.azs, count.index)}"
  cidr_block = "${element(var.public_subnets, count.index)}"
  map_public_ip_on_launch = true

  tags = "${merge("${var.tags}", map("Name", "${var.name}-public-subnet-${element(var.azs, count.index)}"))}"
}

resource "aws_route_table" "public_route_tables" {
  depends_on = ["aws_internet_gateway.gw"]

  count = "${length(var.public_subnets)}"
  vpc_id = "${aws_vpc.main.id}"

  tags = "${merge("${var.tags}", map("Name", "${var.name}-public-routetable-${element(var.azs, count.index)}"))}"
}

resource "aws_route" "public_routes" {
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

################
# Nat Gateway
################

resource "aws_eip" "eips" {
  depends_on = ["aws_internet_gateway.gw"]

  count="${length(var.private_subnets)}"
  vpc = true
}

resource "aws_nat_gateway" "gateways" {
  depends_on = ["aws_internet_gateway.gw"]

  count="${length(var.private_subnets)}"
  allocation_id = "${element(aws_eip.eips.*.id, count.index)}"
  subnet_id = "${element(aws_subnet.public_subnets.*.id, count.index)}"

  tags = "${merge("${var.tags}", map("Name", "${var.name}-nat-gateway-${element(var.azs, count.index)}"))}"
}


################
# Private subnets
################

resource "aws_subnet" "private_subnets" {
  count = "${length(var.private_subnets)}"
  vpc_id = "${aws_vpc.main.id}"
  availability_zone = "${element(var.azs, count.index)}"
  cidr_block = "${element(var.private_subnets, count.index)}"

  tags = "${merge("${var.tags}", map("Name", "${var.name}-private-subnet-${element(var.azs, count.index)}"))}"
}

resource "aws_route_table" "private_route_tables" {
  count = "${length(var.private_subnets)}"
  vpc_id = "${aws_vpc.main.id}"

  tags = "${merge("${var.tags}", map("Name", "${var.name}-private-routetable-${element(var.azs, count.index)}"))}"
}

resource "aws_route" "private_route" {
  count = "${length(var.private_subnets)}"
  route_table_id         = "${element(aws_route_table.private_route_tables.*.id, count.index)}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = "${element(aws_nat_gateway.gateways.*.id, count.index)}"
}

resource "aws_route_table_association" "puivate_route_tables_association" {
  count = "${length(var.public_subnets)}"
  subnet_id      = "${element(aws_subnet.private_subnets.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.private_route_tables.*.id, count.index)}"
}


################
# DB subnets
################

resource "aws_subnet" "database_subnets" {
  count = "${length(var.database_subnets)}"
  vpc_id = "${aws_vpc.main.id}"
  availability_zone = "${element(var.azs, count.index)}"
  cidr_block = "${element(var.database_subnets, count.index)}"

  tags = "${merge("${var.tags}", map("Name", "${var.name}-db-subnet-${element(var.azs, count.index)}"))}"
}

resource "aws_route_table" "database" {
  count = "${length(var.database_subnets)}"
  vpc_id = "${aws_vpc.main.id}"

  tags = "${merge("${var.tags}", map("Name", "${var.name}-db-routetable-${element(var.azs, count.index)}"))}"
}

resource "aws_route_table_association" "database" {
  count = "${length(var.database_subnets)}"

  subnet_id      = "${element(aws_subnet.database_subnets.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.database.*.id, count.index)}"
}

resource "aws_db_subnet_group" "database" {
  name        = "${lower(var.name)}-db-subnet-group"
  description = "Database subnet group"
  subnet_ids  = ["${aws_subnet.database_subnets.*.id}"]

  tags = "${merge("${var.tags}", map("Name", "${var.name}-db-subnet-group"))}"
}
