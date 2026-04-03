output "vpc_id" {
  description = "ID of the firewall VPC."
  value       = module.vpc.vpc_id
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway."
  value       = module.internet_gateway.internet_gateway_id
}

output "nat_gateway_ids" {
  description = "Map of NAT Gateway IDs by availability zone."
  value       = module.nat_gateways.nat_gateway_ids
}

output "subnet_ids" {
  description = "Map of all subnet names to their IDs."
  value       = module.subnets.subnet_ids
}

output "management_subnet_ids" {
  description = "Map of management subnet names to their IDs."
  value = {
    for name, id in module.subnets.subnet_ids : name => id if strcontains(name, "mgmt-")
  }
}

output "trust_subnet_ids" {
  description = "Map of trust subnet names to their IDs."
  value = {
    for name, id in module.subnets.subnet_ids : name => id if strcontains(name, "trust-")
  }
}

output "gwlbe_subnet_ids" {
  description = "Map of GWLBE subnet names to their IDs."
  value = {
    for name, id in module.subnets.subnet_ids : name => id if strcontains(name, "gwlbe-")
  }
}

output "tgw_subnet_ids" {
  description = "Map of TGW subnet names to their IDs."
  value = {
    for name, id in module.subnets.subnet_ids : name => id if strcontains(name, "tgw-")
  }
}

output "route_table_ids" {
  description = "Map of route table types to their IDs."
  value       = module.route_tables.route_table_ids
}
