variable "name_prefix" {
  type        = string
  description = "A prefix to associate to all the App Connector IAM module resources"
  default     = null
}

variable "resource_tag" {
  type        = string
  description = "A tag to associate to all the App Connector IAM module resources"
  default     = null
}

variable "global_tags" {
  type        = map(string)
  description = "Populate any custom user defined tags from a map"
  default     = {}
}

variable "role_enabled" {
  type        = bool
  description = "Determine whether or not to create the cc-callhome-policy IAM Policy and attach it to the CC IAM Role"
  default     = "true"
}

variable "iam_count" {
  type        = number
  description = "Default number IAM roles/policies/profiles to create"
  default     = 1
}
