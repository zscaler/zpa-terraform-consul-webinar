################################################################################
# Generate a unique random string for resource name assignment and key pair
################################################################################
resource "random_string" "suffix" {
  length  = 8
  upper   = false
  special = false
}


################################################################################
# Map default tags with values to be assigned to all tagged resources
################################################################################
locals {
  global_tags = {
    Owner                                                                                = var.owner_tag
    ManagedBy                                                                            = "terraform"
    Vendor                                                                               = "Zscaler"
    "zs-app-connector-cluster/${var.name_prefix}-cluster-${random_string.suffix.result}" = "shared"
  }
}


################################################################################
# The following lines generates a new SSH key pair and stores the PEM file
# locally. The public key output is used as the instance_key passed variable
# to the ec2 modules for admin_ssh_key public_key authentication.
# This is not recommended for production deployments. Please consider modifying
# to pass your own custom public key file located in a secure location.
################################################################################
resource "tls_private_key" "key" {
  algorithm = var.tls_key_algorithm
}

resource "aws_key_pair" "deployer" {
  key_name   = "${var.name_prefix}-key-${random_string.suffix.result}"
  public_key = tls_private_key.key.public_key_openssh
}

resource "local_file" "private_key" {
  content         = tls_private_key.key.private_key_pem
  filename        = "../${var.name_prefix}-key-${random_string.suffix.result}.pem"
  file_permission = "0600"
}

##### KMS Key for Vault Auto-Unseal
# Creates/manages KMS CMK
resource "aws_kms_key" "vault_kms_key" {
  description              = "${var.name_prefix}-vault-kms-${random_string.suffix.result}"
  customer_master_key_spec = var.key_spec
  deletion_window_in_days  = var.customer_master_key_spec
  is_enabled               = var.enabled
  enable_key_rotation      = var.rotation_enabled
  multi_region             = var.multi_region
}

# Add an alias to the key
resource "aws_kms_alias" "key_alias" {
  name          = "alias/${var.name_prefix}-vault-kms-${random_string.suffix.result}"
  target_key_id = aws_kms_key.vault_kms_key.key_id
}

################################################################################
# 1. Create/reference all network infrastructure resource dependencies for all
#    child modules (vpc, igw, nat gateway, subnets, route tables)
################################################################################

module "network" {
  source                      = "../modules/terraform-zsac-network-aws"
  name_prefix                 = var.name_prefix
  resource_tag                = random_string.suffix.result
  global_tags                 = local.global_tags
  az_count                    = var.az_count
  vpc_cidr                    = var.vpc_cidr
  public_subnets              = var.public_subnets
  ac_subnets                  = var.ac_subnets
  associate_public_ip_address = var.associate_public_ip_address
}

################################################################################
# 2. Create ZPA App Connector Group
################################################################################
module "zpa_app_connector_group" {
  source                                       = "../modules/terraform-zpa-app-connector-group"
  app_connector_group_name                     = "${var.aws_region}-${module.network.vpc_id}"
  app_connector_group_description              = "${var.app_connector_group_description}-${var.aws_region}-${module.network.vpc_id}"
  app_connector_group_enabled                  = var.app_connector_group_enabled
  app_connector_group_country_code             = var.app_connector_group_country_code
  app_connector_group_latitude                 = var.app_connector_group_latitude
  app_connector_group_longitude                = var.app_connector_group_longitude
  app_connector_group_location                 = var.app_connector_group_location
  app_connector_group_upgrade_day              = var.app_connector_group_upgrade_day
  app_connector_group_upgrade_time_in_secs     = var.app_connector_group_upgrade_time_in_secs
  app_connector_group_override_version_profile = var.app_connector_group_override_version_profile
  app_connector_group_version_profile_id       = var.app_connector_group_version_profile_id
  app_connector_group_dns_query_type           = var.app_connector_group_dns_query_type
}

################################################################################
# 3. Create ZPA Server Group
################################################################################
module "zpa_server_group" {
  source                                = "../modules/terraform-zpa-server-group"
  server_group_name                     = "${var.aws_region}-${module.network.vpc_id}"
  server_group_description              = "${var.server_group_description}-${var.aws_region}-${module.network.vpc_id}"
  server_group_enabled                  = var.server_group_enabled
  server_group_dynamic_discovery        = var.server_group_dynamic_discovery
  app_connector_group_id                = module.zpa_app_connector_group.app_connector_group_id
  depends_on = [
    module.zpa_app_connector_group
  ]
}

################################################################################
# 4. Create ZPA Provisioning Key (or reference existing if byo set)
################################################################################
module "zpa_provisioning_key" {
  source                            = "../modules/terraform-zpa-provisioning-key"
  enrollment_cert                   = var.enrollment_cert
  provisioning_key_name             = "${var.aws_region}-${module.network.vpc_id}"
  provisioning_key_enabled          = var.provisioning_key_enabled
  provisioning_key_association_type = var.provisioning_key_association_type
  provisioning_key_max_usage        = var.provisioning_key_max_usage
  app_connector_group_id            = module.zpa_app_connector_group.app_connector_group_id
}

################################################################################
# 5. Create ZPA Segment Group
################################################################################
resource "zpa_segment_group" "segment_group" {
  name            = "${var.aws_region}-${module.network.vpc_id}"
  description     = "${var.aws_region}-${module.network.vpc_id}"
  enabled         = true
}

################################################################################
# Locate Latest Amazon Linux 2 AMI for instance use
################################################################################
data "aws_ssm_parameter" "amazon_linux_latest" {
  name  = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

locals {
  ami_selected = data.aws_ssm_parameter.amazon_linux_latest.value
}

################################################################################
# 6. Create specified number of AC appliances
################################################################################
module "ac_vm" {
  source                      = "../modules/terraform-zsac-acvm-aws"
  ac_count                    = var.ac_count
  name_prefix                 = var.name_prefix
  resource_tag                = random_string.suffix.result
  global_tags                 = local.global_tags
  ac_subnet_ids               = module.network.ac_subnet_ids
  instance_key                = aws_key_pair.deployer.key_name
  user_data                   = local.al2userdata
  instance_type               = var.instance_type
  iam_instance_profile        = module.ac_iam.iam_instance_profile_id
  security_group_id           = module.ac_sg.ac_security_group_id
  associate_public_ip_address = var.associate_public_ip_address
  ami_id                      = contains(var.ami_id, "") ? [local.ami_selected] : var.ami_id

  depends_on = [
    module.zpa_provisioning_key,
    local_file.al2_user_data_file,
  ]
}

# Write the file to local filesystem for storage/reference
resource "local_file" "al2_user_data_file" {
  content  = local.al2userdata
  filename = "../user_data"
}

################################################################################
# 7. Create IAM Policy, Roles, and Instance Profiles to be assigned to AC.
#    Default behavior will create 1 of each IAM resource per AC VM. Set variable
#    "reuse_iam" to true if you would like a single IAM profile created and
#    assigned to ALL App Connectors instead.
################################################################################
module "ac_iam" {
  source              = "../modules/terraform-zsac-iam-aws"
  iam_count           = var.reuse_iam == false ? var.ac_count : 1
  name_prefix         = var.name_prefix
  resource_tag        = random_string.suffix.result
  global_tags         = local.global_tags
  role_enabled        = var.role_enabled
}


################################################################################
# 8. Create Security Group and rules to be assigned to the App Connector
#    interface. Default behavior will create 1 of each SG resource per AC VM.
#    Set variable "reuse_security_group" to true if you would like a single
#    security group created and assigned to ALL App Connectors instead.
################################################################################
module "ac_sg" {
  source       = "../modules/terraform-zsac-sg-aws"
  sg_count     = var.reuse_security_group == false ? var.ac_count : 1
  name_prefix  = var.name_prefix
  resource_tag = random_string.suffix.result
  global_tags  = local.global_tags
  vpc_id       = module.network.vpc_id
}

################################################################################
# Locate Latest Ubuntu Linux AMI for Consul Server and Web instance use
################################################################################
data "aws_ssm_parameter" "ubuntu" {
  name = "/aws/service/canonical/ubuntu/server/20.04/stable/current/amd64/hvm/ebs-gp2/ami-id"
}

locals {
  ubuntu_ami_selected = data.aws_ssm_parameter.ubuntu.value
}

################################################################################
# 9. Create Consul Server
################################################################################
module "consul_server" {
  source                    = "../modules/terraform-zsac-consul-server"
  name_prefix               = var.name_prefix
  resource_tag              = random_string.suffix.result
  global_tags               = local.global_tags
  vpc_id                    = module.network.vpc_id
  public_subnet             = module.network.public_subnet_ids[0]
  instance_key              = aws_key_pair.deployer.key_name
  user_data                 = local.consulserveruserdata
  instance_type             = var.instance_type
  consul_ami_id             = local.ubuntu_ami_selected
  depends_on = [
    local_file.consul_server_user_data_file,
  ]
}

# Write the file to local filesystem for storage/reference
resource "local_file" "consul_server_user_data_file" {
  content  = local.consulserveruserdata
  filename = "../user_data"
}

################################################################################
# 10. Create the specified AC VMs via Launch Template and Autoscaling Group
################################################################################
module "web_asg" {
  source                      = "../modules/terraform-zsac-asg-web-aws"
  name_prefix                 = var.name_prefix
  resource_tag                = random_string.suffix.result
  global_tags                 = local.global_tags
  ac_subnet_ids               = module.network.ac_subnet_ids
  instance_key                = aws_key_pair.deployer.key_name
  user_data                   = local.webserveruserdata
  instance_type               = var.instance_type
  iam_instance_profile        = module.ac_iam.iam_instance_profile_id
  vpc_id                      = module.network.vpc_id
  associate_public_ip_address = var.associate_public_ip_address
  ami_id                      = local.ubuntu_ami_selected


  desired_capacity          = var.desired_capacity
  max_size                  = var.max_size
  min_size                  = var.min_size
  target_cpu_util_value     = var.target_cpu_util_value
  health_check_grace_period = var.health_check_grace_period
  launch_template_version   = var.launch_template_version
  target_tracking_metric    = var.target_tracking_metric

  depends_on = [
    local_file.web_server_user_data_file,
  ]
}

#Write the file to local filesystem for storage/reference
resource "local_file" "web_server_user_data_file" {
  content  = local.webserveruserdata
  filename = "../user_data"
}

################################################################################
# Generate CTS Configuration File from Template
################################################################################

locals {
  nia = templatefile("../../zpa_nia/example/config.hcl.example", {
    consul   = module.consul_server.public_ip
  })
}

resource "local_file" "nia-config" {
  content  = local.nia
  filename = "../../zpa_nia/example/config.hcl"
}

################################################################################
# Generate CTS TFVARs Configuration File from Template
################################################################################

locals {
  zpa_objects = templatefile("../../zpa_nia/example/terraform.tfvars.example", {
    byo_app_connector_group_name  = "${var.aws_region}-${module.network.vpc_id}"
    byo_segment_group_name        = "${var.aws_region}-${module.network.vpc_id}"
    byo_server_group_name         = "${var.aws_region}-${module.network.vpc_id}"
  })
}

resource "local_file" "zpa_objects" {
  content  = local.zpa_objects
  filename = "../../zpa_nia/example/terraform.tfvars"
}