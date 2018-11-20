output "bastion_sg" {
  description = "Bastion Access Security Group"
  value       = "${aws_security_group.bastion.security_group_id}"
}
