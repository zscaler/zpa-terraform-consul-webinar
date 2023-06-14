output "consul_services" {
  description = "Application Segment Consul Locals"
  value       = local.consul_services
}
/*
################################################################################
# Application Segment Outputs
################################################################################
output "zpa_application_segment" {
  description = "The ZPA Application Segment"
  value       = zpa_application_segment.this
}

################################################################################
# Segment Group Outputs
################################################################################
output "zpa_segment_group" {
  description = "The ZPA Segment Group"
  value       = zpa_segment_group.this
}

################################################################################
# Server Group Outputs
################################################################################
output "zpa_server_group" {
  description = "The ZPA Server Group"
  value       = zpa_server_group.this
}

################################################################################
# App Connector Group Outputs
################################################################################
output "zpa_app_connector_group" {
  description = "The ZPA App Connector Group"
  value       = zpa_app_connector_group.this
}
*/