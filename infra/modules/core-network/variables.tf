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
variable "subnets" {
  description = "Map of subnet configurations."
  type = map(object({
    cidr_block        = string
    availability_zone = string
    segment           = optional(string)
  }))
}
variable "availability_zones" {
  description = "List of exactly 3 availability zones for resilience."
  type        = list(string)
  validation {
    condition     = length(var.availability_zones) == 3
    error_message = "Exactly 3 availability zones must be provided."
  }
}

variable "nat_gateway_subnets" {
  description = "Map of subnet IDs for NAT gateway placement. Each key is the AZ name, and the value is the subnet ID."
  type        = map(string)
  default     = {}
}


variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}
