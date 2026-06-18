terraform {
  required_version = ">= 1.0"
}

variable "create" {
  description = "Whether to create route tables."
  type        = bool
  default     = true
}

variable "vpc_id" {
  description = "ID of the VPC where route tables will be created."
  type        = string
}

variable "name" {
  description = "Name tag for the route table."
  type        = string
}

variable "routes" {
  description = <<EOF
Map of routes to create. Each key is a route identifier, and the value includes:
- destination_cidr_block (optional)
- destination_ipv6_cidr_block (optional)
- gateway_id (optional)
- nat_gateway_id (optional)
- vpc_peering_connection_id (optional)
- transit_gateway_id (optional)
- egress_only_gateway_id (optional)
EOF
  type = map(object({
    destination_cidr_block      = optional(string)
    destination_ipv6_cidr_block = optional(string)
    gateway_id                  = optional(string)
    nat_gateway_id              = optional(string)
    vpc_peering_connection_id   = optional(string)
    transit_gateway_id          = optional(string)
    egress_only_gateway_id      = optional(string)
  }))
  default = {}
}

variable "route_table_associations" {
  description = "Map of route table associations. Each key is a unique identifier and value contains subnet_id."
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
