output "vpc_id" {
  description = "ID of the created VPC."
  value       = aws_vpc.this.id
}

output "internet_gateway_id" {
  description = "ID of the created Internet Gateway."
  value       = aws_internet_gateway.this.id
}

output "subnet_ids" {
  description = "Map of subnet name -> subnet id."
  value       = { for k, v in aws_subnet.this : k => v.id }
}

output "public_subnet_ids" {
  description = "List of public subnet IDs."
  value       = [for name in local.public_subnet_names : aws_subnet.this[name].id]
}

output "private_subnet_ids" {
  description = "List of private subnet IDs."
  value       = [for name in local.private_subnet_names : aws_subnet.this[name].id]
}

output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs (one per public subnet when enabled)."
  value       = aws_nat_gateway.this[*].id
}

output "route_table_ids" {
  description = "Map of route table keys -> route table id. Includes public, private, and additional route tables."
  value = merge(
    { public = aws_route_table.public.id },
    var.create_single_private_route_table ? { private = aws_route_table.private.id } : { for k, v in aws_route_table.private_per_subnet : k => v.id },
    { for k, v in aws_route_table.additional : k => v.id }
  )
}

output "security_group_ids" {
  description = "Map of security group name -> security group id."
  value       = { for k, v in aws_security_group.this : k => v.id }
}
