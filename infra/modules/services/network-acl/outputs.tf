output "network_acl_id" {
  description = "Network ACL id."
  value       = one(aws_network_acl.this[*].id)
}

output "network_acl_ids" {
  description = "Backward-compatible alias map containing the single network ACL id."
  value       = { this = one(aws_network_acl.this[*].id) }
}
