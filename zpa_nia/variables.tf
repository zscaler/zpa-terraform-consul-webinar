variable "services" {
  description = "Consul services monitored by Consul NIA"
  type = map(
    object({
      id        = string
      name      = string
      address   = string
      port      = number
      status    = string
      meta      = map(string)
      tags      = list(string)
      namespace = string

      node                  = string
      node_id               = string
      node_address          = string
      node_datacenter       = string
      node_tagged_addresses = map(string)
      node_meta             = map(string)
      cts_user_defined_meta = map(string)
    })
  )
}

################################################################################
# Optional Prefix
################################################################################
variable "appsegment_prefix" {
  type        = string
  description = "(Optional) Prefix added to the dynamic application segment created by Consul"
  default     = ""
}

variable "cts_prefix" {
  type        = string
  description = "(Optional) Prefix that will be applied to all objects created via Consul-Terraform-Sync"
  default     = "CTS_"
}

################################################################################
# Application Segment Variables
################################################################################

variable "app_segment_enabled" {
  type        = bool
  description = "Indicates if the Zscaler Client Connector receives CNAME DNS records from the connectors"
  default     = true
}

variable "app_segment_health_reporting" {
  type        = string
  description = "Health reporting for the application segment created by Consul-Terraform-Sync. "
  validation {
    condition     = var.app_segment_health_reporting != "NONE" || var.app_segment_health_reporting != "ON_ACCESS" || var.app_segment_health_reporting != "CONTINUOUS"
    error_message = "The variable health_reporting must be \"NONE\", \"ON_ACCESS\", or \"CONTINUOUS\"."
  }
  default = "ON_ACCESS"
}

variable "app_segment_icmp_access_type" {
  type        = string
  description = "ICMP Access Type for the application segment created by Consul-Terraform-Sync. "
  validation {
    condition     = var.app_segment_icmp_access_type != "NONE" || var.app_segment_icmp_access_type != "PING" || var.app_segment_icmp_access_type != "PING_TRACEROUTING"
    error_message = "The variable icmp_access_type must be \"NONE\", \"PING\", or \"PING_TRACEROUTING\"."
  }
  default = "PING"
}

variable "app_segment_bypass_type" {
  type        = string
  description = "Bypass Type for the application segment created by Consul-Terraform-Sync. "
  validation {
    condition     = var.app_segment_bypass_type != "NEVER" || var.app_segment_bypass_type != "ALWAYS" || var.app_segment_bypass_type != "ON_NET"
    error_message = "The variable bypass_type must be \"NEVER\", \"ALWAYS\", or \"ON_NET\"."
  }
  default = "NEVER"
}

variable "app_segment_is_cname_enabled" {
  type        = bool
  description = "Indicates if the Zscaler Client Connector receives CNAME DNS records from the connectors"
  default     = true
}

variable "app_segment_tcp_keep_alive" {
  type        = string
  description = "Indicates if the Zscaler Client Connector receives CNAME DNS records from the connectors"
  default     = "1"
}

################################################################################
# Segment Group Variables
################################################################################
variable "byo_segment_group" {
  type        = bool
  description = "Bring your own Segment Group"
  default     = false
}

variable "byo_segment_group_name" {
  type        = string
  description = "User provided existing Segment Group ID"
  default     = null
}

variable "byo_segment_group_id" {
  type        = string
  description = "User provided existing Segment Group ID"
  default     = null
}

variable "segment_group_name" {
  type        = string
  description = "Name of the segment group."
  default     = "SegmentGroup"
}

variable "segment_group_description" {
  type        = string
  description = "Description of the segment group."
  default     = "SegmentGroup"
}

variable "segment_group_enabled" {
  type        = bool
  description = "Whether this segment group is enabled or not."
  default     = true
}

################################################################################
# Server Group Variables
################################################################################
variable "byo_server_group" {
  type        = bool
  description = "Bring your own Server Group"
  default     = false
}

variable "byo_server_group_name" {
  type        = string
  description = "User provided existing Server Group ID"
  default     = null
}

variable "byo_server_group_id" {
  type        = string
  description = "User provided existing Server Group ID"
  default     = null
}
variable "server_group_name" {
  type        = string
  description = "This field defines the name of the server group."
  default     = "ServerGroup"
}

variable "server_group_description" {
  type        = string
  description = "This field is the description of the server group."
  default     = "ServerGroup"
}

variable "server_group_enabled" {
  type        = bool
  description = "This field defines if the server group is enabled or disabled."
  default     = true
}

variable "server_group_dynamic_discovery" {
  type        = bool
  description = "This field controls dynamic discovery of the servers."
  default     = true
}

################################################################################
# App Connector Group Variables
################################################################################
variable "byo_app_connector_group" {
  type        = bool
  description = "Bring your own App Connector Group"
  default     = false
}

variable "byo_app_connector_group_name" {
  type        = string
  description = "User provided existing App Connector Group ID"
  default     = null
}

variable "byo_app_connector_group_id" {
  type        = string
  description = "User provided existing App Connector Group ID"
  default     = null
}

variable "app_connector_group_name" {
  type        = string
  description = "Name of the App Connector Group."
  default     = "AppConnector"
}

variable "app_connector_group_description" {
  type        = string
  description = "Description of the App Connector Group."
  default     = "AppConnector"
}

variable "app_connector_group_enabled" {
  type        = bool
  description = "Whether this App Connector Group is enabled or not."
  default     = true
}

variable "app_connector_group_latitude" {
  type        = string
  description = "Whether this App Connector Group is enabled or not."
  default     = "37.3382082"
}

variable "app_connector_group_longitude" {
  type        = string
  description = "Whether this App Connector Group is enabled or not."
  default     = "-121.8863286"
}

variable "app_connector_group_location" {
  type        = string
  description = "Location of the App Connector Group."
  default     = "San Jose, CA, USA"
}

variable "app_connector_group_country_code" {
  type        = string
  description = "Code of the Country where the app connector is located i.e US or CA"
  default     = "US"
}

variable "app_connector_group_city_country" {
  type        = string
  description = "Code of the Country where the app connector is located i.e US or CA"
  default     = "San Jose, US"
}

variable "app_connector_group_upgrade_day" {
  type        = string
  description = "App Connectors in this group will attempt to update to a newer version of the software during this specified day."
  default     = "SUNDAY"
}

variable "app_connector_group_upgrade_time_in_secs" {
  type        = string
  description = "App Connectors in this group will attempt to update to a newer version of the software during this specified time."
  default     = "66600"
}

variable "app_connector_group_override_version_profile" {
  type        = bool
  description = "Whether the default version profile of the App Connector Group is applied or overridden."
  default     = true
}

variable "select_connector_close_to_app" {
  type        = bool
  description = ""
  default     = true
}

variable "app_connector_group_version_profile_name" {
  type        = string
  description = "Name of the version profile"
  validation {
    condition     = var.app_connector_group_version_profile_name != "Default" || var.app_connector_group_version_profile_name != "Default" || var.app_connector_group_version_profile_name != "New Release"
    error_message = "The attribute version_profile_name must be \"Default \", \"Previous Default\", or \"New Release\"."
  }
  default = "2"
}

variable "app_connector_group_dns_query_type" {
  type        = string
  description = "Whether to enable IPv4 or IPv6, or both, for DNS resolution of all applications in the App Connector Group"
  validation {
    condition     = var.app_connector_group_dns_query_type != "IPV4" || var.app_connector_group_dns_query_type != "IPV6" || var.app_connector_group_dns_query_type != "IPV4_IPV6"
    error_message = "The attribute dns_query_type must be \"IPV4\", \"IPV6\", or \"IPV4_IPV6\"."
  }
  default = "IPV4_IPV6"
}