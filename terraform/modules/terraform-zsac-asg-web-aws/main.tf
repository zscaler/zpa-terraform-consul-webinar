################################################################################
# Pull VPC information
################################################################################
data "aws_vpc" "selected" {
  id = var.vpc_id
}

###################################################################################
# Create launch template for Web Server clients autoscaling group instance creation.
###################################################################################
resource "aws_launch_template" "web_launch_template" {
  name          = "${var.name_prefix}-web-launch-template-${var.resource_tag}"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.instance_key
  user_data     = base64encode(var.user_data)


  iam_instance_profile {
    name = aws_iam_instance_profile.instance_profile.name
  }

  tag_specifications {
    resource_type = "instance"
    tags          = merge(var.global_tags, { Name = "${var.name_prefix}-web-asg-${var.resource_tag}" })
  }

  tag_specifications {
    resource_type = "network-interface"
    tags          = merge(var.global_tags, { Name = "${var.name_prefix}-web-nic-asg-${var.resource_tag}" })
  }
  network_interfaces {
    description                 = "Interface for Web Server traffic"
    device_index                = 0
    security_groups               = [aws_security_group.web_sg.id]
    associate_public_ip_address = var.associate_public_ip_address
  }

  lifecycle {
    create_before_destroy = true
  }
}


################################################################################
# Create Web Server autoscaling group
################################################################################
resource "aws_autoscaling_group" "web_asg" {
  name                      = "${var.name_prefix}-web-asg-${var.resource_tag}"
  vpc_zone_identifier       = distinct(var.ac_subnet_ids)
  desired_capacity          = var.desired_capacity
  max_size                  = var.max_size
  min_size                  = var.min_size
  health_check_type         = "EC2"
  health_check_grace_period = var.health_check_grace_period

  launch_template {
    id      = aws_launch_template.web_launch_template.id
    version = var.launch_template_version
  }

  enabled_metrics = [
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupMaxSize",
    "GroupMinSize",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances",
  ]

  tag {
      key                 = "Name"
      value               = "${var.name_prefix}-web"
      propagate_at_launch = true
    }

  tag {
      key                 = "Env"
      value               = "consul"
      propagate_at_launch = true
    }
  # lifecycle {
  #   ignore_changes = [desired_capacity]
  # }
}

################################################################################
# Create autoscaling group policy based on dynamic Target Tracking Scaling on
# average CPU
################################################################################
resource "aws_autoscaling_policy" "web_asg_target_tracking_policy" {
  name                   = "${var.name_prefix}-web-asg-target-policy-${var.resource_tag}"
  autoscaling_group_name = aws_autoscaling_group.web_asg.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = var.target_tracking_metric
    }
    target_value = var.target_cpu_util_value
  }
}

################################################################################
# Define AssumeRole access for EC2
################################################################################
data "aws_iam_policy_document" "web_instance_assume_role" {
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
data "aws_iam_policy_document" "web_auto_discover_cluster" {
  version = "2012-10-17"
  statement {
    sid       = "AllowConsulDescribeInstanceASG"
    effect    = "Allow"
    actions   = [
        "ec2:DescribeInstances",
        "ec2:DescribeTags",
        "autoscaling:DescribeAutoScalingGroups"
        ]
    resources = ["*"]
  }
}

resource "aws_iam_instance_profile" "instance_profile" {
  name_prefix = "${var.name_prefix}-zs-web-profile-${var.resource_tag}"
  role        = aws_iam_role.instance_role.name
}

resource "aws_iam_role" "instance_role" {
  name_prefix        = "${var.name_prefix}-zs-web-iam-role-${var.resource_tag}"
  assume_role_policy = data.aws_iam_policy_document.web_instance_assume_role.json
}

resource "aws_iam_role_policy" "auto_discover_cluster" {
  name   = "${var.name_prefix}-zs-web-auto-discover-cluster-${var.resource_tag}"
  role   = aws_iam_role.instance_role.id
  policy = data.aws_iam_policy_document.web_auto_discover_cluster.json
}

################################################################################
# Create pre-defined AWS Security Groups and rules for Consul Server
################################################################################
resource "aws_security_group" "web_sg" {
  name        = "${var.name_prefix}-web-sg-${var.resource_tag}"
  description = "Allow SSH access to consul server and outbound internet access"
  vpc_id      = data.aws_vpc.selected.id

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.global_tags,
    { Name = "${var.name_prefix}-web-sg-${var.resource_tag}" }
  )
}

resource "aws_security_group_rule" "ssh" {
  protocol          = "TCP"
  from_port         = 22
  to_port           = 22
  type              = "ingress"
  cidr_blocks       = var.web_nsg_source_prefix
  security_group_id = aws_security_group.web_sg.id
}

resource "aws_security_group_rule" "http" {
  protocol          = "TCP"
  from_port         = 80
  to_port           = 80
  type              = "ingress"
  cidr_blocks       = var.web_nsg_source_prefix
  security_group_id = aws_security_group.web_sg.id
}

resource "aws_security_group_rule" "server_rpc" {
  protocol          = "TCP"
  from_port         = 8300
  to_port           = 8300
  type              = "ingress"
  cidr_blocks       = ["10.0.0.0/16"]
  security_group_id = aws_security_group.web_sg.id
}

resource "aws_security_group_rule" "lan_serf" {
  protocol          = "TCP"
  from_port         = 8301
  to_port           = 8301
  type              = "ingress"
  cidr_blocks       = ["10.0.0.0/16"]
  security_group_id = aws_security_group.web_sg.id
}

resource "aws_security_group_rule" "icmp" {
  protocol          = "icmp"
  from_port         = -1
  to_port           = -1
  type              = "ingress"
  cidr_blocks       = var.web_nsg_source_prefix
  security_group_id = aws_security_group.web_sg.id
}

resource "aws_security_group_rule" "intranet" {
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  type              = "egress"
  cidr_blocks       = var.web_nsg_source_prefix
  security_group_id = aws_security_group.web_sg.id
}
