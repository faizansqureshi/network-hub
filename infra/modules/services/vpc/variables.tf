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
List of subnets to create.
Each subnet object must include:
- name: unique key used for resources and outputs
- cidr: subnet CIDR block
- availability_zone: the AZ to create the subnet in
- type: one of "public", "private", "isolated"
- map_public_ip_on_launch: whether to map public IPs on launch
EOF
  type = list(object({
    name                  = string
    cidr                  = string
    availability_zone     = string
    type                  = string
    map_public_ip_on_launch = bool
  }))
  default = []
}

variable "enable_nat_gateway" {
  description = "Whether to create NAT Gateways for private subnet internet access. Creates one NAT gateway per public subnet."
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

variable "security_groups" {
  description = <<EOF
Security groups to create in this VPC.
Each security group object must include:
- name
- description
- ingress (list of rules)
- egress (list of rules)

Rule schema:
- from_port
- to_port
- protocol
- cidr_blocks (optional)
- ipv6_cidr_blocks (optional)
- security_groups (optional)
- prefix_list_ids (optional)
- self (optional)
EOF
  type = list(object({
    name        = string
    description = string
    tags        = optional(map(string), {})
    ingress = optional(list(object({
      from_port        = number
      to_port          = number
      protocol         = string
      cidr_blocks      = optional(list(string), [])
      ipv6_cidr_blocks = optional(list(string), [])
      security_groups  = optional(list(string), [])
      prefix_list_ids  = optional(list(string), [])
      self             = optional(bool, false)
    })), [])
    egress = optional(list(object({
      from_port        = number
      to_port          = number
      protocol         = string
      cidr_blocks      = optional(list(string), [])
      ipv6_cidr_blocks = optional(list(string), [])
      security_groups  = optional(list(string), [])
      prefix_list_ids  = optional(list(string), [])
      self             = optional(bool, false)
    })), [{
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }])
  }))
  default = []
}
