variable "name_prefix" {
  type        = string
  description = "A prefix to associate to all the Workload module resources"
  default     = null
}

variable "resource_tag" {
  type        = string
  description = "A tag to associate to all the Workload module resources"
  default     = null
}

variable "user_data" {
  type        = string
  description = "App Init data"
}

variable "global_tags" {
  type        = map(string)
  description = "Populate any custom user defined tags from a map"
  default     = {}
}

variable "vpc_id" {
  type        = string
  description = "App Connector VPC ID"
}

variable "public_subnet" {
  type        = string
  description = "The public subnet where the consul server has to be attached"
}

variable "instance_type" {
  type        = string
  default     = "t2.micro"
  validation {
    condition = (
      var.instance_type == "t2.micro" ||
      var.instance_type == "t3.medium"
    )
    error_message = "Input instance_type must be set to an approved vm instance type."
  }
}

variable "consul_nsg_source_prefix" {
  type        = list(string)
  description = "CIDR blocks of trusted networks for consul server ssh access"
  default     = ["0.0.0.0/0"]
}

variable "instance_key" {
  type        = string
  description = "SSH Key for instances"
}

variable "consul_ami_id" {
  type        = string
  description = "AMI ID(s) to be used for deploying App Connector appliances. Ideally all VMs should be on the same AMI ID as templates always pull the latest from AWS Marketplace. This variable is provided if a customer desires to override/retain an old ami for existing deployments rather than upgrading and forcing a replacement. It is also inputted as a list to facilitate if a customer desired to manually upgrade select ACs deployed based on the ac_count index"
  default     = ""
}

