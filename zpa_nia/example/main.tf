terraform {
  required_providers {
    zpa = {
      source  = "zscaler/zpa"
      version = "~>2.7.0"
    }
  }
  required_version = ">= 0.13"
}

provider "zpa" {
}

module "zpa_application_segment_module" {
  source = "../"
  services = var.services

  # Bring-Your-Own Variables
  byo_segment_group            = var.byo_segment_group
  byo_segment_group_name       = var.byo_segment_group_name
  byo_segment_group_id         = var.byo_segment_group_id
  byo_server_group             = var.byo_server_group
  byo_server_group_name        = var.byo_server_group_name
  byo_server_group_id          = var.byo_server_group_id
  byo_app_connector_group      = var.byo_app_connector_group
  byo_app_connector_group_name = var.byo_app_connector_group_name
  byo_app_connector_group_id   = var.byo_app_connector_group_id
}
