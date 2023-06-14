################################################################################
# Local Variables to Support Application Segment Domain Names, TCP and UDP Ports
################################################################################
locals {
  consul_services = {
    # Set the value of id as the key for the map
    for k, v in var.services : v.name => {
      # Set the value of name, the ip address of the node - iterating via key, and setting the port
      domain_names = (var.services[k].node_address != "" ? var.services[k].node : var.services[k].address), src_port_start = v.port, src_port_end = v.port
    }...
  }
}

################################################################################
# ZPA Application Segment
################################################################################
# Create a Application Segment
# https://help.zscaler.com/zpa/application-segment-use-cases

resource "zpa_application_segment" "this" {
  for_each = local.consul_services

  name                          = replace("${var.appsegment_prefix}${each.key}", "/[^0-9A-Za-z]/", "-")
  description                   = "Service for ${var.cts_prefix}${each.key} created by Consul-Terraform-Sync"
  enabled                       = var.app_segment_enabled
  is_cname_enabled              = var.app_segment_is_cname_enabled
  health_reporting              = var.app_segment_health_reporting
  bypass_type                   = var.app_segment_bypass_type
  select_connector_close_to_app = var.select_connector_close_to_app
  tcp_keep_alive                = var.app_segment_tcp_keep_alive
  icmp_access_type              = var.app_segment_icmp_access_type
  domain_names                  = each.value.*.domain_names
  segment_group_id              = data.zpa_segment_group.this.id
  tcp_port_ranges               = [one(distinct(each.value.*.src_port_start)), one(distinct(each.value.*.src_port_end))]
  server_groups {
    id = [data.zpa_server_group.this.id]
  }
  lifecycle {
    create_before_destroy = true
  }
  depends_on = [data.zpa_segment_group.this, data.zpa_server_group.this, data.zpa_app_connector_group.this]
}

################################################################################
# ZPA Segment Group
################################################################################
# Create a Segment Group
# https://help.zscaler.com/zpa/application-segment-group-use-cases
resource "zpa_segment_group" "this" {
  # count = var.byo_segment_group ? 1 : 0
  count = var.byo_segment_group == false ? 1 : 0

  name                   = "${var.cts_prefix}${var.segment_group_name}"
  description            = "${var.cts_prefix}${var.segment_group_description}"
  enabled                = var.segment_group_enabled
}

# Or reference an existing Segment Group
data "zpa_segment_group" "this" {
  name = var.byo_segment_group == false ? zpa_segment_group.this[0].name : var.byo_segment_group_name
  id   = var.byo_segment_group == false ? zpa_segment_group.this.*.id[0] : var.byo_segment_group_id
}

################################################################################
# ZPA Server Group
################################################################################
# Create a Server Group
# https://help.zscaler.com/zpa/application-server-group-use-cases
resource "zpa_server_group" "this" {
  # count = var.byo_server_group ? 1 : 0
  count = var.byo_server_group == false ? 1 : 0

  name              = "${var.cts_prefix}${var.server_group_name}"
  description       = "${var.cts_prefix}${var.server_group_description}"
  enabled           = var.server_group_enabled
  dynamic_discovery = var.server_group_dynamic_discovery
  app_connector_groups {
    id = [data.zpa_app_connector_group.this.id]
  }
}

# Or reference an existing Server Group
data "zpa_server_group" "this" {
  name = var.byo_server_group == false ? zpa_server_group.this[0].name : var.byo_server_group_name
  id   = var.byo_server_group == false ? zpa_server_group.this.*.id[0] : var.byo_server_group_id
}

################################################################################
# ZPA App Connector Group
################################################################################
# Create an App Connector Group
# https://help.zscaler.com/zpa/app-connector-group-use-cases
resource "zpa_app_connector_group" "this" {
  # count = var.byo_app_connector_group ? 1 : 0
  count = var.byo_app_connector_group == false ? 1 : 0

  name                     = "${var.cts_prefix}${var.app_connector_group_name}"
  description              = "${var.cts_prefix}${var.app_connector_group_description}"
  enabled                  = var.app_connector_group_enabled
  city_country             = var.app_connector_group_city_country
  country_code             = var.app_connector_group_country_code
  latitude                 = var.app_connector_group_latitude
  longitude                = var.app_connector_group_longitude
  location                 = var.app_connector_group_location
  upgrade_day              = var.app_connector_group_upgrade_day
  upgrade_time_in_secs     = var.app_connector_group_upgrade_time_in_secs
  override_version_profile = var.app_connector_group_override_version_profile
  version_profile_name     = var.app_connector_group_version_profile_name
  dns_query_type           = var.app_connector_group_dns_query_type
}

# Or reference an existing App Connector Group
data "zpa_app_connector_group" "this" {
  name = var.byo_app_connector_group == false ? zpa_app_connector_group.this[0].name : var.byo_app_connector_group_name
  id   = var.byo_app_connector_group == false ? zpa_app_connector_group.this.*.id[0] : var.byo_app_connector_group_id
}