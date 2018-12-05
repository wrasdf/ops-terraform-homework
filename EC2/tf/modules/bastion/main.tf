terraform {
  required_version = ">= 0.11.10" # introduction of Local Values configuration language feature
}

data "template_file" "bastion" {
  template      = "${file("${path.module}/user_data/bastion.sh")}"

  vars {
    log_group_name = "${aws_cloudwatch_log_group.bastion.name}"
  }
}

data "template_cloudinit_config" "config" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "bation.sh"
    content_type = "text/x-shellscript"
    content      = "${data.template_file.bastion.rendered}"
  }
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
  name = "${var.name}-bastion-log"
  retention_in_days = 7

  tags = "${merge("${var.tags}", map("Name", "${var.name}-bastion-log"))}"
}

resource "aws_launch_configuration" "bastion" {
  name_prefix   = "${var.name}-"
  key_name      = "${var.bastion_ssh_key}"
  image_id      = "${lookup(var.amis, var.region)}"
  instance_type = "${var.bastion_instance_type}"
  enable_monitoring = false

  user_data     = "${data.template_cloudinit_config.config.rendered}"
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

  // TODO need update this
  vpc_zone_identifier       = "${var.azs}"

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
  name = "${var.name}-bastion-instance-profile"
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
  vpc_id      = "${var.vpc_id}"

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
