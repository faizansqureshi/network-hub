terraform {
  required_version = ">= 1.0"
}

variable "create" {
  description = "Whether to create network ACLs."
  type        = bool
  default     = true
}

variable "vpc_id" {
  description = "ID of the VPC where network ACLs will be created."
  type        = string
}

variable "network_acls" {
  description = "Map of network ACLs to create. Each key is the ACL identifier."
  type = map(object({
    name = string
  }))
  default = {}
}

variable "ingress_rules" {
  description = <<EOF
Map of ingress rules. Each key is a rule identifier, value includes:
- nacl_key: key of the network ACL (from var.network_acls)
- rule_number: rule priority number
- protocol: protocol name (tcp, udp, -1 for all)
- rule_action: "allow" or "deny"
- cidr_block, ipv6_cidr_block, from_port, to_port, icmp_type, icmp_code (optional)
EOF
  type = map(object({
    nacl_key        = string
    rule_number     = number
    protocol        = string
    rule_action     = string
    cidr_block      = optional(string)
    ipv6_cidr_block = optional(string)
    from_port       = optional(number)
    to_port         = optional(number)
    icmp_type       = optional(number)
    icmp_code       = optional(number)
  }))
  default = {}
}

variable "egress_rules" {
  description = "Map of egress rules. Same schema as ingress_rules."
  type = map(object({
    nacl_key        = string
    rule_number     = number
    protocol        = string
    rule_action     = string
    cidr_block      = optional(string)
    ipv6_cidr_block = optional(string)
    from_port       = optional(number)
    to_port         = optional(number)
    icmp_type       = optional(number)
    icmp_code       = optional(number)
  }))
  default = {}
}

variable "nacl_associations" {
  description = "Map of network ACL associations. Each key is a unique identifier, value includes nacl_key and subnet_id."
  type = map(object({
    nacl_key  = string
    subnet_id = string
  }))
  default = {}
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}
