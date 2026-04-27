terraform {
  required_version = ">= 1.0"
}

variable "create" {
  description = "Whether to create NAT gateways."
  type        = bool
  default     = true
}


variable "subnet_id" {
  description = "ID of the subnet where the NAT gateway will be placed."
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}
