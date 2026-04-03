output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.this.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC."
  value       = aws_vpc.this.cidr_block
}

output "secondary_cidr_association_id" {
  description = "ID of the secondary CIDR association, if configured."
  value       = try(aws_vpc_ipv4_cidr_block_association.secondary[0].id, null)
}

