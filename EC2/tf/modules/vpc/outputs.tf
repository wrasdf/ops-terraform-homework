output "vpc_id" {
  description = "The ID of the VPC"
  value       = "${aws_vpc.main.id}"
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = ["${aws_subnet.public_subnets.*.id}"]
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = ["${aws_subnet.private_subnets.*.id}"]
}

output "database_subnets" {
  description = "List of IDs of database subnets"
  value       = ["${aws_subnet.database_subnets.*.id}"]
}

output "nat_public_ips" {
  description = "List of public Elastic IPs created for AWS NAT Gateway"
  value       = ["${aws_eip.eips.*.public_ip}"]
}

output "azs" {
  description = "List of vpc zone"
  value       = "${var.azs}"
}
