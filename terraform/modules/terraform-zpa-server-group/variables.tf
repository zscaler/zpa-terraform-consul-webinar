variable "server_group_name" {
  type        = string
  description = "Name of the Server Group"
}

variable "server_group_description" {
  type        = string
  description = "Optional: Description of the Server Group"
  default     = ""
}

variable "server_group_enabled" {
  type        = bool
  description = "Whether this Server Group is enabled or not"
  default     = true
}

variable "server_group_dynamic_discovery" {
  type        = bool
  description = "Whether this Server Group has dynamic discovery enabled or not"
  default     = true
}

variable "app_connector_group_id" {
  type        = string
  description = "List of App Connector Group IDs attached to the Server Group"
  default     = ""
}
