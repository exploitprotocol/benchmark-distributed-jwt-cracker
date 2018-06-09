variable "stack_name" {
  type = "string"
}

variable "token" {
  type = "string"
}

variable "alphabet" {
  type    = "string"
  default = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
}

variable "num_clients" {
  type    = "string"
  default = 4
}

variable "num_procs" {
  type    = "string"
  default = 2
}

variable "ami" {
  type = "string"
}

variable "authorized_ssh_key" {
  type = "string"
}

variable "instance_type" {
  type    = "string"
  default = "t2.medium"
}

variable "num_client_processes" {
  type    = "string"
  default = 2
}

provider "aws" {
  region = "eu-west-1"
}

data "aws_vpc" "main" {
  default = true
}

resource "aws_security_group" "instances" {
  name        = "JWTCracker-${var.stack_name}-instances"
  description = "JWT Cracker server SG"
  vpc_id      = "${data.aws_vpc.main.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9900
    to_port     = 9901
    protocol    = "tcp"
    cidr_blocks = ["${data.aws_vpc.main.cidr_block}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Stack = "JWTCracker-${var.stack_name}"
    App   = "JWTCracker"
  }
}

data "template_file" "user_data_server" {
  template = "${file("user_data_server.tpl")}"

  vars {
    ssh_key  = "${var.authorized_ssh_key}"
    hostname = "JWTCracker-${var.stack_name}-server"
    alphabet = "${var.alphabet}"
    token    = "${var.token}"
  }
}

data "template_file" "user_data_client" {
  count    = "${var.num_clients}"
  template = "${file("user_data_client.tpl")}"

  vars {
    ssh_key   = "${var.authorized_ssh_key}"
    hostname  = "JWTCracker-${var.stack_name}-client${count.index}"
    server_ip = "${aws_instance.server.private_ip}"
    num_procs = "${var.num_procs}"
  }
}

resource "aws_instance" "server" {
  ami                  = "${var.ami}"
  instance_type        = "${var.instance_type}"
  user_data            = "${data.template_file.user_data_server.rendered}"
  security_groups      = ["${aws_security_group.instances.name}"]
  iam_instance_profile = "${aws_iam_instance_profile.jwt_machine_profile.name}"

  tags {
    Name  = "JWTCracker-${var.stack_name}-server"
    Stack = "JWTCracker-${var.stack_name}"
    App   = "JWTCracker"
  }
}

resource "aws_instance" "client" {
  count                = "${var.num_clients}"
  ami                  = "${var.ami}"
  instance_type        = "${var.instance_type}"
  user_data            = "${element(data.template_file.user_data_client.*.rendered, count.index)}"
  security_groups      = ["${aws_security_group.instances.name}"]
  iam_instance_profile = "${aws_iam_instance_profile.jwt_machine_profile.name}"

  tags {
    Name  = "JWTCracker-${var.stack_name}-client${count.index}"
    Stack = "JWTCracker-${var.stack_name}"
    App   = "JWTCracker"
  }
}

resource "aws_iam_role" "jwt_machine" {
  name = "JWTCracker-${var.stack_name}"

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

resource "aws_iam_policy" "jwt_machine_policy" {
  name        = "JWTCracker-${var.stack_name}-policy"
  description = "Allows logs and self termination"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:Describe*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": [
        "ec2:TerminateInstances"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams"
      ],
      "Resource": [
        "arn:aws:logs:*:*:*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "jwt_machine_policy_attach" {
  role       = "${aws_iam_role.jwt_machine.name}"
  policy_arn = "${aws_iam_policy.jwt_machine_policy.arn}"
}

resource "aws_iam_instance_profile" "jwt_machine_profile" {
  name = "JWTCracker-${var.stack_name}-profile"
  role = "${aws_iam_role.jwt_machine.name}"
}
