terraform {
  required_version = ">= 1.0"
}

variable "create" {
  description = "Whether to create subnets."
  type        = bool
  default     = true
}

variable "vpc_id" {
  description = "ID of the VPC where subnets will be created."
  type        = string
}

variable "subnets" {
  description = <<EOF
Map of subnets where each key is the subnet name.
Each subnet object must include:
- cidr_block: subnet CIDR block
- availability_zone: the AZ to create the subnet in
- type: one of "public", "private", "isolated"
- map_public_ip_on_launch: whether to map public IPs on launch
EOF
  type = map(object({
    cidr_block              = string
    availability_zone       = string
    type                    = string
    map_public_ip_on_launch = bool
  }))
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}
