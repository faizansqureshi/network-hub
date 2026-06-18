output "vpc_id" {
  description = "ID of the VPC."
  value       = module.core_network.vpc_id
}

output "subnet_ids" {
  description = "Map of all subnet names to their IDs."
  value       = module.core_network.subnet_ids
}

output "subnet_ids_by_segment" {
  description = "Map of segment -> map of subnet names to IDs."
  value       = module.core_network.subnet_ids_by_segment
}
