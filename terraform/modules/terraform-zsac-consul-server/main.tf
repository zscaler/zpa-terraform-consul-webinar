################################################################################
# Pull VPC information
################################################################################
data "aws_vpc" "selected" {
  id = var.vpc_id
}

################################################################################
# Create Consul Server EC2 with automatic public IP association
################################################################################
resource "aws_instance" "consul_server" {
  ami                         = var.consul_ami_id
  instance_type               = var.instance_type
  key_name                    = var.instance_key
  subnet_id                   = var.public_subnet
  vpc_security_group_ids      = [aws_security_group.consul_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.instance_profile.name
  user_data                   = base64encode(var.user_data)
  associate_public_ip_address = true

  connection {
    type        = "ssh"
    user        = "ubuntu"
    host        = self.public_ip
    private_key = var.tls_private_key
  }

  provisioner "file" {
    source      = "${path.module}/script.sh"
    destination = "/tmp/script.sh"
  }

  provisioner "remote-exec" {
    inline = ["cloud-init status --wait > /dev/null 2>&1"]
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/script.sh",
      "sh /tmp/script.sh",
    ]
  }

  tags = {
    Name = "${var.name_prefix}-consul"
    Env  = "consul"
  }
}

################################################################################
# Create pre-defined AWS Security Groups and rules for Consul Server
################################################################################
resource "aws_security_group" "consul_sg" {
  name        = "${var.name_prefix}-consul-sg-${var.resource_tag}"
  description = "Allow access to consul server and outbound internet access"
  vpc_id      = data.aws_vpc.selected.id

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.global_tags,
    { Name = "${var.name_prefix}-consul-sg-${var.resource_tag}" }
  )
}

resource "aws_security_group_rule" "ssh" {
  protocol          = "TCP"
  from_port         = 22
  to_port           = 22
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.consul_sg.id
}

resource "aws_security_group_rule" "vault_8200" {
  protocol          = "TCP"
  from_port         = 8200
  to_port           = 8200
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.consul_sg.id
}

resource "aws_security_group_rule" "vault_8201" {
  protocol          = "TCP"
  from_port         = 8201
  to_port           = 8201
  type              = "ingress"
  cidr_blocks       = ["10.0.0.0/16"]
  security_group_id = aws_security_group.consul_sg.id
}

resource "aws_security_group_rule" "server_rpc" {
  protocol          = "TCP"
  from_port         = 8300
  to_port           = 8300
  type              = "ingress"
  cidr_blocks       = ["10.0.0.0/16"]
  security_group_id = aws_security_group.consul_sg.id
}

resource "aws_security_group_rule" "lan_serf" {
  protocol          = "TCP"
  from_port         = 8301
  to_port           = 8301
  type              = "ingress"
  cidr_blocks       = ["10.0.0.0/16"]
  security_group_id = aws_security_group.consul_sg.id
}

resource "aws_security_group_rule" "http_api" {
  protocol          = "TCP"
  from_port         = 8500
  to_port           = 8500
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.consul_sg.id
}

resource "aws_security_group_rule" "grpc_api" {
  protocol          = "TCP"
  from_port         = 8502
  to_port           = 8502
  type              = "ingress"
  cidr_blocks       = var.consul_nsg_source_prefix
  security_group_id = aws_security_group.consul_sg.id
}

resource "aws_security_group_rule" "icmp" {
  protocol          = "icmp"
  from_port         = -1
  to_port           = -1
  type              = "ingress"
  cidr_blocks       = var.consul_nsg_source_prefix
  security_group_id = aws_security_group.consul_sg.id
}

resource "aws_security_group_rule" "intranet" {
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  type              = "egress"
  cidr_blocks       = var.consul_nsg_source_prefix
  security_group_id = aws_security_group.consul_sg.id
}

resource "aws_security_group_rule" "outbound" {
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  type              = "egress"
  cidr_blocks       = [data.aws_vpc.selected.cidr_block]
  security_group_id = aws_security_group.consul_sg.id
}

################################################################################
# Define AssumeRole access for EC2
################################################################################
data "aws_iam_policy_document" "instance_assume_role" {
  version = "2012-10-17"
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

################################################################################
# Define AssumeRole access Cluster Auto Discover
################################################################################
data "aws_iam_policy_document" "auto_discover_cluster" {
  version = "2012-10-17"
  statement {
    sid       = "AllowConsulDescribeInstanceASG"
    effect    = "Allow"
    actions   = [
        "ec2:DescribeInstances",
        "ec2:DescribeTags",
        "autoscaling:DescribeAutoScalingGroups",
        ]
    resources = ["*"]
  }
  statement {
    sid       = "VaultKMSUnseal"
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:DescribeKey",
    ]
  }
}

resource "aws_iam_instance_profile" "instance_profile" {
  name_prefix = "${var.name_prefix}-zs-host-profile-${var.resource_tag}"
  role        = aws_iam_role.instance_role.name
}

resource "aws_iam_role" "instance_role" {
  name_prefix        = "${var.name_prefix}-zs-node-iam-role-${var.resource_tag}"
  assume_role_policy = data.aws_iam_policy_document.instance_assume_role.json
}

resource "aws_iam_role_policy" "auto_discover_cluster" {
  name   = "${var.name_prefix}-zs-auto-discover-cluster-${var.resource_tag}"
  role   = aws_iam_role.instance_role.id
  policy = data.aws_iam_policy_document.auto_discover_cluster.json
}