terraform {
  required_version = ">= 1.0"
}

variable "name" {
  description = "Name of the VPC."
  type        = string
}

variable "cidr_block" {
  description = "CIDR block for the VPC."
  type        = string
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
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}

