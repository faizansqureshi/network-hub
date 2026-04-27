output "vpc_id" {
  description = "ID of the firewall VPC."
  value       = module.vpc.vpc_id
}


output "subnet_ids" {
  description = "Map of all subnet names to their IDs."
  value       = module.subnets.subnet_ids
}

output "subnet_ids_by_segment" {
  description = "Map of segment -> map of subnet names to IDs."
  value       = module.subnets.subnet_ids_by_segment
}

output "management_subnet_ids" {
  description = "Map of management subnet names to their IDs."
  value       = lookup(module.subnets.subnet_ids_by_segment, "mgmt", {})
}

output "trust_subnet_ids" {
  description = "Map of trust subnet names to their IDs."
  value       = lookup(module.subnets.subnet_ids_by_segment, "trust", {})
}

output "gwlep_subnet_ids" {
  description = "Map of GWLEP subnet names to their IDs."
  value       = lookup(module.subnets.subnet_ids_by_segment, "gwlep", {})
}

output "gwlbe_subnet_ids" {
  description = "Backward-compatible alias for GWLEP subnet IDs."
  value       = lookup(module.subnets.subnet_ids_by_segment, "gwlep", {})
}

output "tgw_subnet_ids" {
  description = "Map of TGW subnet names to their IDs."
  value       = lookup(module.subnets.subnet_ids_by_segment, "tgw", {})
}
