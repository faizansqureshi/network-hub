output "nat_gateway_ids" {
  description = "Map of NAT gateway name -> nat gateway id."
  value       = { for k, v in aws_nat_gateway.this : k => v.id }
}

output "nat_gateway_public_ips" {
  description = "Map of NAT gateway name -> elastic IP address."
  value       = { for k, v in aws_eip.nat : k => v.public_ip }
}
