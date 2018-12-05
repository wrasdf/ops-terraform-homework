terraform {
  required_version = ">= 0.11.10" # introduction of Local Values configuration language feature
}

data "aws_vpc" "main" {
  // todo -> use vpc stack output
  id = "vpc-asfsdafd"
}

data "aws_availability_zones" "available" {
  // todo -> need to pass value
  zas = ${var.azs}
}

data "aws_subnet_ids" "public_subnets" {
  // todo -> need to pass in
  vpc_id = "${var.vpc_id}"
}

data "aws_subnet_ids" "private_subnets" {
  // todo -> use vpc stack output
  vpc_id = "${var.vpc_id}"
}

data "aws_security_group" "bastion" {
  // need to be pass in from bastion sg
  id = ""
}

resource "aws_cloudwatch_log_group" "app" {
  name = "${var.name}-ec2-app-log"
  retention_in_days = 7

  tags = "${merge("${var.tags}", map("Name", "${var.name}-ec2-app-log"))}"
}

resource "aws_security_group" "elb" {
  name        = "${var.name}-ec2-elb-sg"
  description = "Allow http to client host"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
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

  tags = "${merge("${var.tags}", map("Name", "${var.name}-ec2-elb-sg"))}"
}

resource "aws_elb" "app" {
  name               = "${var.name}-ec2-elb"

  subnets = ["${element(data.aws_subnet_ids.public_subnets.ids, count.index)}"]
  security_groups = ["${data.aws_security_group.bastion.id}"]

  listener {
    lb_port           = 80
    lb_protocol       = "http"
    instance_port     = 80
    instance_protocol = "http"
  }

  # Ingnore for now
  # listener {
  #   instance_port      = 800
  #   instance_protocol  = "http"
  #   lb_port            = 443
  #   lb_protocol        = "https"
  #   ssl_certificate_id = "arn:aws:iam::123456789012:server-certificate/certName"
  # }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    target              = "HTTP:80/health"
    interval            = 20
  }

  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags = "${merge("${var.tags}", map("Name", "${var.name}-ec2-elb"))}"
}

resource "aws_autoscaling_group" "app" {

  name               = "${var.name}-ec2-app-asg"
  desired_capacity   = 1
  min_size           = 1
  max_size           = 3

  health_check_grace_period = 300
  health_check_type         = "ELB"
  launch_configuration      = "${aws_launch_configuration.app.name}"

  // TODO need update this
  vpc_zone_identifier       = ["${element(data.aws_subnet_ids.private_subnets.ids, count.index)}"]

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
    "${merge("${var.tags}", map("Name", "${var.name}-ec2-app-asg", "propagate_at_launch", "true"))}"
  ]
}

resource "aws_security_group" "app" {
  name        = "${var.name}-ec2-app-sg"
  description = "EC2 Security Group"
  vpc_id      = "${data.aws_vpc.main.id}"

  egress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = "${merge("${var.tags}", map("Name", "${var.name}-ec2-app-sg"))}"
}

resource "aws_security_group_rule" "bastion_ingress_rules" {

  type              = "ingress"
  security_group_id = "${aws_security_group.app.id}"

  from_port = "22"
  to_port   = "22"
  protocol  = "tcp"

  source_security_group_id = "${data.aws_security_group.bastion.id}"
}

resource "aws_security_group_rule" "bastion_ingress_rules" {

  type              = "ingress"
  security_group_id = "${aws_security_group.app.id}"

  from_port = "80"
  to_port   = "80"
  protocol  = "tcp"

  source_security_group_id = "${aws_security_group.elb.id}"
}

resource "aws_launch_configuration" "app" {
  name_prefix   = "${var.name}-"
  key_name      = "${var.app_ssh_key}"
  image_id      = "${var.app_ami_id}"
  instance_type = "${var.app_instance_type}"
  enable_monitoring = false

  # user_data     = "${data.template_cloudinit_config.config.rendered}"
  user_data     = "${file(format("%s/user_data/app.sh", path.module))}"
  security_groups  = [
    "${aws_security_group.app.id}"
  ]
  iam_instance_profile = "${aws_iam_instance_profile.app.name}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_instance_profile" "app" {
  name = "${var.name}-ec2-instance-profile"
  role = "${aws_iam_role.app.name}"
}

resource "aws_iam_role" "app" {
  name               = "${var.name}-ec2-app-role"
  path               = "/"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "app" {
  name   = "app-server"
  role   = "${aws_iam_role.app.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:*",
        "elasticloadbalancing:DescribeInstanceHealth",
        "autoscaling:DescribeTags"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "logs" {
  name   = "app-logs"
  role   = "${aws_iam_role.app.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:Describe*"
      ],
      "Effect": "Allow",
      "Resource": "${aws_cloudwatch_log_group.log.arn}"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "ecr" {
  name   = "read-only-access-to-ecr"
  role   = "${aws_iam_role.app.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:GetRepositoryPolicy",
        "ecr:DescribeRepositories",
        "ecr:ListImages",
        "ecr:BatchGetImage"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "email" {
  name   = "allow-send-email"
  role   = "${aws_iam_role.app.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ses:SendEmail"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "cloudwatch" {
  name   = "allow-cloudwatch"
  role   = "${aws_iam_role.app.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "cloudwatch:PutMetricData",
        "cloudwatch:EnableAlarmActions",
        "cloudwatch:PutMetricAlarm"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}
