output "route_table_id" {
  description = "Route table id."
  value       = one(aws_route_table.this[*].id)
}
