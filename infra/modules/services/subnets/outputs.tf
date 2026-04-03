output "subnet_ids" {
  description = "Map of subnet name -> subnet id."
  value       = { for k, v in aws_subnet.this : k => v.id }
}

output "subnets" {
  description = "Map of subnet name -> subnet object."
  value       = aws_subnet.this
}
