variable "aws_region" {
  description = "AWS region for deployment."
  type        = string
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

variable "subnets" {
  description = "Map of subnet configurations."
  type        = map(object({
    cidr_block              = string
    availability_zone       = string

  }))
}   

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}
