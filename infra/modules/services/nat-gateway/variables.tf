terraform {
  required_version = ">= 1.0"
}

variable "create" {
  description = "Whether to create NAT gateways."
  type        = bool
  default     = true
}

variable "nat_gateways" {
  description = <<EOF
Map of NAT gateways to create.
Each key is the NAT gateway name, and the value includes:
- subnet_id: ID of the public subnet where the NAT gateway will be placed
EOF
  type = map(object({
    subnet_id = string
  }))
  default = {}
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}
