output "subnet_ids" {
  description = "Map of subnet name -> subnet id."
  value       = { for k, v in aws_subnet.this : k => v.id }
}

output "ids" {
  description = "Backward-compatible alias of subnet_ids."
  value       = { for k, v in aws_subnet.this : k => v.id }
}

output "subnets" {
  description = "Map of subnet name -> subnet object."
  value       = aws_subnet.this
}

output "subnet_ids_by_segment" {
  description = "Map of segment -> map of subnet name -> subnet id."
  value = {
    for segment in toset([
      for subnet_name, subnet in var.subnets : lower(try(subnet.segment, split("-", subnet_name)[0]))
      ]) : segment => {
      for subnet_name, subnet in var.subnets :
      subnet_name => aws_subnet.this[subnet_name].id
      if lower(try(subnet.segment, split("-", subnet_name)[0])) == segment
    }
  }
}
