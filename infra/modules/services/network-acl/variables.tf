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

variable "name" {
  description = "Name tag for the network ACL."
  type        = string
}

variable "ingress_rules" {
  description = <<EOF
Map of ingress rules. Override this input to customize defaults.
Each key is a rule identifier, value includes:
- rule_number: rule priority number
- protocol: protocol name (tcp, udp, -1 for all)
- rule_action: "allow" or "deny"
- cidr_block, ipv6_cidr_block, from_port, to_port, icmp_type, icmp_code (optional)
EOF
  type = map(object({
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
  default = {
    "allow-all" = {
      rule_number = 100
      protocol    = "-1"
      rule_action = "allow"
      cidr_block  = "0.0.0.0/0"
    }
  }
}

variable "egress_rules" {
  description = "Map of egress rules. Override this input to customize defaults. Same schema as ingress_rules."
  type = map(object({
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
  default = {
    "allow-all" = {
      rule_number = 100
      protocol    = "-1"
      rule_action = "allow"
      cidr_block  = "0.0.0.0/0"
    }
  }
}

variable "nacl_associations" {
  description = "Map of network ACL associations. Each key is a unique identifier and value contains subnet_id."
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
