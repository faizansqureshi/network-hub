terraform {
  required_version = ">= 1.0"
}

variable "name" {
  description = "Base name prefix used for created resources."
  type        = string
  default     = "vpc"
}

variable "cidr_block" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "secondary_cidr_block" {
  description = "Optional secondary IPv4 CIDR block to associate with the VPC."
  type        = string
  default     = null
}

variable "enable_dns_support" {
  description = "Should the VPC have DNS support enabled?"
  type        = bool
  default     = true
}

variable "enable_dns_hostnames" {
  description = "Should instances launched in the VPC get DNS hostnames?"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to all resources created by this module."
  type        = map(string)
  default     = {}
}

variable "subnets" {
  description = <<EOF
Map of subnets to create where each key is the subnet name.
Each subnet object must include:
- cidr: subnet CIDR block
- availability_zone: the AZ to create the subnet in
- type: one of "public", "private", "isolated"
- map_public_ip_on_launch: whether to map public IPs on launch
EOF
  type = map(object({
    cidr                  = string 
    availability_zone     = string
    type                  = string
    map_public_ip_on_launch = bool
  }))
  default = {}
}

variable "enable_nat_gateway" {
  description = "Whether to create NAT Gateways for private subnet internet access. Creates one NAT gateway per public subnet."
  type        = bool
  default     = true
}

variable "enable_internet_gateway" {
  description = "Whether to create and attach an Internet Gateway to the VPC."
  type        = bool
  default     = true
}

variable "create_single_private_route_table" {
  description = "Whether to use a single private route table (true) or create one per private subnet (false)."
  type        = bool
  default     = true
}

variable "additional_route_tables" {
  description = <<EOF
Optional additional route tables.
Each entry is a map key used as the resource key, and the value must include:
- name: friendly name for the route table
- subnet_names: list of subnet names (from `var.subnets`) to associate the route table with
- routes: list of route definitions (see schema below)

Route definition schema:
- destination_cidr_block (required)
- ipv6_destination_cidr_block (optional)
- gateway_id (optional)
- nat_gateway_id (optional)
- vpc_peering_connection_id (optional)
- transit_gateway_id (optional)
- egress_only_internet_gateway_id (optional)
EOF
  type = map(object({
    name        = string
    subnet_names = list(string)
    routes = list(object({
      destination_cidr_block            = string
      ipv6_destination_cidr_block       = optional(string)
      gateway_id                        = optional(string)
      nat_gateway_id                    = optional(string)
      vpc_peering_connection_id         = optional(string)
      transit_gateway_id                = optional(string)
      egress_only_internet_gateway_id   = optional(string)
    }))
  }))
  default = {}
}

variable "network_acls" {
  description = <<EOF
Optional network ACLs to create and associate with subnets.
Each entry is a map key used as the resource key, and the value must include:
- name: friendly name for the network ACL
- subnet_names: list of subnet names (from `var.subnets`) to associate with this ACL
- ingress: list of ingress rules
- egress: list of egress rules

Rule schema:
- rule_number (required)
- protocol (required)
- rule_action (required, "allow" or "deny")
- cidr_block (optional)
- ipv6_cidr_block (optional)
- from_port (optional)
- to_port (optional)
- icmp_type (optional)
- icmp_code (optional)
EOF
  type = map(object({
    name         = string
    subnet_names = list(string)
    ingress = list(object({
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
    egress = list(object({
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
  }))
  default = {}
}

