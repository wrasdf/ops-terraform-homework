terraform {
  required_version = ">= 0.11.10" # introduction of Local Values configuration language feature
}

data "template_file" "user_data" {
  // TODO
}

data "aws_vpc" "main" {
  // todo fix this
  id = "adf"
}

data "aws_iam_policy_document" "assume_role_ec2" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "logs" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:Describe*",
    ]

    resources = ["arn:aws:logs:*:*:*"]
  }
}

resource "aws_cloudwatch_log_group" "bastion" {
  name = "${var.name}-log"
  retention_in_days = 7

  tags = "${merge("${var.tags}", map("Name", "${var.name}-loggroup"))}"
}

resource "aws_launch_configuration" "bastion" {
  name_prefix   = "${var.name}-"
  key_name      = "${var.bastion_ssh_key}"
  image_id      = "${var.bastion_ami_id}"
  instance_type = "${var.bastion_instance_type}"
  enable_monitoring = false

  // TODO
  # user_data     = "${data.template_file.user_data.rendered}"
  security_groups  = [
    "${aws_security_group.bastion.id}"
  ]
  iam_instance_profile = "${aws_iam_instance_profile.bastion.name}"

  lifecycle {
    create_before_destroy = true
  }

}

resource "aws_autoscaling_group" "bastion" {

  name               = "${var.name}-asg"
  desired_capacity   = 0
  min_size           = 0
  max_size           = 1

  health_check_grace_period = 300
  health_check_type         = "ELB"
  launch_configuration      = "${aws_launch_configuration.bastion.name}"
  # vpc_zone_identifier       = // TODO

  termination_policies      = [
    "OldestInstance"
  ]
  timeouts {
    delete = "15m"
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = [
    "${merge("${var.tags}", map("Name", "${var.name}-asg", "propagate_at_launch", "true"))}"
  ]

}

resource "aws_iam_instance_profile" "bastion" {
  name = "${var.name}-instance-profile"
  role = "${aws_iam_role.bastion.name}"
}

resource "aws_iam_role" "bastion" {
  name               = "${var.name}-bastion-role"
  path               = "/"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role_ec2.json}"
}

resource "aws_iam_role_policy" "bastion" {
  name   = "${var.name}-bastion-policy"
  role   = "${aws_iam_role.bastion.id}"
  policy = "${data.aws_iam_policy_document.logs.json}"
}

resource "aws_security_group" "bastion" {
  name        = "${var.name}-sg"
  description = "Allow all inbound traffic"
  vpc_id      = "${data.aws_vpc.main.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = "${merge("${var.tags}", map("Name", "${var.name}-sg"))}"

}
