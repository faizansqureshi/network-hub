output "network_acl_ids" {
  description = "Map of network ACL key -> network ACL id."
  value       = { for k, v in aws_network_acl.this : k => v.id }
}
