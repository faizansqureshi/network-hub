terraform {
  required_version = ">= 1.0"
}

variable "create" {
  description = "Whether to create an Internet Gateway."
  type        = bool
  default     = true
}

variable "vpc_id" {
  description = "ID of the VPC to attach the Internet Gateway to."
  type        = string
}

variable "name" {
  description = "Name of the Internet Gateway."
  type        = string
}

variable "tags" {
  description = "Tags to apply to the Internet Gateway."
  type        = map(string)
  default     = {}
}
