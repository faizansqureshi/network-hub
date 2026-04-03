resource "aws_network_acl" "this" {
  for_each = var.create ? var.network_acls : {}

  vpc_id = var.vpc_id
  tags   = merge(var.tags, { Name = each.value.name })
}

resource "aws_network_acl_rule" "ingress" {
  for_each = var.create ? var.ingress_rules : {}

  network_acl_id  = aws_network_acl.this[each.value.nacl_key].id
  egress          = false
  rule_number     = each.value.rule_number
  protocol        = each.value.protocol
  rule_action     = each.value.rule_action
  cidr_block      = try(each.value.cidr_block, null)
  ipv6_cidr_block = try(each.value.ipv6_cidr_block, null)
  from_port       = try(each.value.from_port, null)
  to_port         = try(each.value.to_port, null)
  icmp_type       = try(each.value.icmp_type, null)
  icmp_code       = try(each.value.icmp_code, null)
}

resource "aws_network_acl_rule" "egress" {
  for_each = var.create ? var.egress_rules : {}

  network_acl_id  = aws_network_acl.this[each.value.nacl_key].id
  egress          = true
  rule_number     = each.value.rule_number
  protocol        = each.value.protocol
  rule_action     = each.value.rule_action
  cidr_block      = try(each.value.cidr_block, null)
  ipv6_cidr_block = try(each.value.ipv6_cidr_block, null)
  from_port       = try(each.value.from_port, null)
  to_port         = try(each.value.to_port, null)
  icmp_type       = try(each.value.icmp_type, null)
  icmp_code       = try(each.value.icmp_code, null)
}

resource "aws_network_acl_association" "this" {
  for_each = var.create ? var.nacl_associations : {}

  subnet_id      = each.value.subnet_id
  network_acl_id = aws_network_acl.this[each.value.nacl_key].id
}
