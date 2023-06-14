################################################################################
# Create ZPA App Connector Provisioning Key
################################################################################
# Retrieve Connector Enrollment Cert ID
data "zpa_enrollment_cert" "connector_cert" {
  name = var.enrollment_cert
}

resource "zpa_provisioning_key" "provisioning_key" {
  name               = var.provisioning_key_name
  enabled            = var.provisioning_key_enabled
  association_type   = var.provisioning_key_association_type
  max_usage          = var.provisioning_key_max_usage
  enrollment_cert_id = data.zpa_enrollment_cert.connector_cert.id
  zcomponent_id      = var.app_connector_group_id
}