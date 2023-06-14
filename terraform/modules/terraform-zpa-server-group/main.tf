################################################################################
# Create ZPA App Connector Group
################################################################################
# Create App Connector Group
resource "zpa_server_group" "server_group" {
  name              = var.server_group_name
  description       = var.server_group_description
  enabled           = var.server_group_enabled
  dynamic_discovery = var.server_group_dynamic_discovery
  app_connector_groups {
    id = [var.app_connector_group_id]
  }
}