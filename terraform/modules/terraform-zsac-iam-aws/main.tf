
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
}

resource "aws_iam_instance_profile" "instance_profile" {
  count       = var.iam_count
  name_prefix = var.iam_count > 1 ? "${var.name_prefix}-zs-${count.index + 1}-host-profile-${var.resource_tag}" : "${var.name_prefix}-zs-host-profile-${var.resource_tag}"
  role        = aws_iam_role.instance_role[count.index].name
}

resource "aws_iam_role" "instance_role" {
  count              = var.role_enabled ? var.iam_count : 0
  name_prefix        = var.iam_count > 1 ? "${var.name_prefix}-zs-${count.index + 1}-node-iam-role-${var.resource_tag}" : "${var.name_prefix}-cc_node_iam_role-${var.resource_tag}"
  assume_role_policy = data.aws_iam_policy_document.instance_assume_role.json
}

resource "aws_iam_role_policy" "auto_discover_cluster" {
  count  = var.role_enabled ? var.iam_count : 0
  name   = "${var.name_prefix}-zs-${count.index + 1}-auto-discover-cluster-${var.resource_tag}"
  role   = aws_iam_role.instance_role[count.index].id
  policy = data.aws_iam_policy_document.auto_discover_cluster.json
}