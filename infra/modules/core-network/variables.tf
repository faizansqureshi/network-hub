terraform {
  required_version = ">= 1.0"
}

variable "name" {
  description = "Name prefix for all resources."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
}

variable "availability_zones" {
  description = "List of exactly 3 availability zones for resilience."
  type        = list(string)
  validation {
    condition     = length(var.availability_zones) == 3
    error_message = "Exactly 3 availability zones must be provided."
  }
}

variable "subnet_cidrs" {
  description = <<EOF
Subnet CIDR blocks organized by type. Each type must have exactly 3 CIDRs (one per AZ).
Example:
  management = ["10.0.1.0/24", "10.0.4.0/24", "10.0.7.0/24"]
  trust      = ["10.0.2.0/24", "10.0.5.0/24", "10.0.8.0/24"]
  gwlbe      = ["10.0.3.0/24", "10.0.6.0/24", "10.0.9.0/24"]
  tgw        = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
EOF
  type = object({
    management = list(string)
    trust      = list(string)
    gwlbe      = list(string)
    tgw        = list(string)
  })
  validation {
    condition = (
      length(var.subnet_cidrs.management) == 3 &&
      length(var.subnet_cidrs.trust) == 3 &&
      length(var.subnet_cidrs.gwlbe) == 3 &&
      length(var.subnet_cidrs.tgw) == 3
    )
    error_message = "Each subnet type must have exactly 3 CIDR blocks."
  }
}

variable "create_subnets" {
  description = "Whether to create subnets."
  type        = bool
  default     = true
}

variable "create_internet_gateway" {
  description = "Whether to create an Internet Gateway (required for management subnet routing)."
  type        = bool
  default     = true
}

variable "create_nat_gateways" {
  description = "Whether to create NAT Gateways (required for GWLBE subnet internet egress)."
  type        = bool
  default     = true
}

variable "create_route_tables" {
  description = "Whether to create route tables and associations."
  type        = bool
  default     = true
}

variable "tgw_additional_routes" {
  description = <<EOF
Optional additional routes to add to TGW route table (e.g., Transit Gateway attachment routes).
Each route object schema:
- destination_cidr_block (required)
- transit_gateway_id (optional)
- vpc_peering_connection_id (optional)
- nat_gateway_id (optional)
- gateway_id (optional)
EOF
  type = list(object({
    destination_cidr_block    = string
    transit_gateway_id        = optional(string)
    vpc_peering_connection_id = optional(string)
    nat_gateway_id            = optional(string)
    gateway_id                = optional(string)
  }))
  default = []
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}
