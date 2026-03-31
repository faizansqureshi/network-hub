// This module creates an AWS VPC with multiple subnets, route tables, NAT gateways, and an Internet Gateway.
//
// Usage example (in a root module):
//
// module "vpc" {
//   source = "./modules/services/vpc"
//
//   name       = "example"
//   cidr_block = "10.0.0.0/16"
//   secondary_cidr_block = "10.1.0.0/16"
//   enable_internet_gateway = true
//
//   subnets = {
//     "public-1" = {
//       cidr                    = "10.0.1.0/24"
//       availability_zone       = "eu-west-1a"
//       type                    = "public"
//       map_public_ip_on_launch = true
//     }
//     "private-1" = {
//       cidr                    = "10.0.2.0/24"
//       availability_zone       = "eu-west-1a"
//       type                    = "private"
//       map_public_ip_on_launch = false
//     }
//   }
// }

locals {
  subnet_map = var.subnets

  public_subnet_names   = [for subnet_name, subnet in var.subnets : subnet_name if lower(subnet.type) == "public"]
  private_subnet_names  = [for subnet_name, subnet in var.subnets : subnet_name if lower(subnet.type) == "private"]
  isolated_subnet_names = [for subnet_name, subnet in var.subnets : subnet_name if lower(subnet.type) == "isolated"]
}

resource "aws_vpc" "this" {
  cidr_block           = var.cidr_block
  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames

  tags = merge(var.tags, { Name = var.name })
}

resource "aws_vpc_ipv4_cidr_block_association" "secondary" {
  count = var.secondary_cidr_block != null ? 1 : 0

  vpc_id     = aws_vpc.this.id
  cidr_block = var.secondary_cidr_block
}

resource "aws_internet_gateway" "this" {
  count  = var.enable_internet_gateway ? 1 : 0
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, { Name = "${var.name}-igw" })
}

resource "aws_subnet" "this" {
  for_each = local.subnet_map

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = each.value.map_public_ip_on_launch

  tags = merge(var.tags, {
    Name = each.key
    Type = each.value.type
  })
}

resource "aws_eip" "nat" {
  count = var.enable_nat_gateway ? length(local.public_subnet_names) : 0

  tags = merge(var.tags, { Name = "${var.name}-nat-eip-${count.index}" })
}

resource "aws_nat_gateway" "this" {
  count = var.enable_nat_gateway ? length(local.public_subnet_names) : 0

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.this[local.public_subnet_names[count.index]].id

  tags = merge(var.tags, { Name = "${var.name}-nat-${count.index}" })

  depends_on = [aws_internet_gateway.this]
}

locals {
  nat_gateway_by_az = {
    for idx, ng in aws_nat_gateway.this : aws_subnet.this[local.public_subnet_names[idx]].availability_zone => ng.id
  }

  network_acl_associations = flatten([
    for nacl_key, nacl in var.network_acls : [
      for subnet_name in nacl.subnet_names : {
        nacl_key    = nacl_key
        subnet_name = subnet_name
      }
    ]
  ])

  network_acl_ingress_rules = flatten([
    for nacl_key, nacl in var.network_acls : [
      for rule in nacl.ingress : {
        key      = "${nacl_key}-ingress-${rule.rule_number}"
        nacl_key = nacl_key
        rule     = rule
      }
    ]
  ])

  network_acl_egress_rules = flatten([
    for nacl_key, nacl in var.network_acls : [
      for rule in nacl.egress : {
        key      = "${nacl_key}-egress-${rule.rule_number}"
        nacl_key = nacl_key
        rule     = rule
      }
    ]
  ])

  additional_route_table_associations = flatten([
    for rt_key, rt in var.additional_route_tables : [
      for subnet_name in rt.subnet_names : {
        rt_key      = rt_key
        subnet_name = subnet_name
      }
    ]
  ])
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, { Name = "${var.name}-public-rt" })
}

resource "aws_route" "public_internet" {
  count = var.enable_internet_gateway ? 1 : 0

  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this[0].id
}

resource "aws_route_table_association" "public" {
  for_each = toset(local.public_subnet_names)

  subnet_id      = aws_subnet.this[each.key].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  count  = var.create_single_private_route_table && length(local.private_subnet_names) > 0 ? 1 : 0
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, { Name = "${var.name}-private-rt" })
}

resource "aws_route" "private_default" {
  count = var.create_single_private_route_table && length(local.private_subnet_names) > 0 && length(aws_nat_gateway.this) > 0 ? 1 : 0

  route_table_id         = aws_route_table.private[0].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[0].id
}

resource "aws_route_table_association" "private" {
  count = var.create_single_private_route_table ? length(local.private_subnet_names) : 0

  subnet_id      = aws_subnet.this[local.private_subnet_names[count.index]].id
  route_table_id = aws_route_table.private[0].id
}

resource "aws_route_table" "private_per_subnet" {
  for_each = var.create_single_private_route_table ? {} : { for name in local.private_subnet_names : name => name }

  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "${var.name}-private-rt-${each.key}" })
}

resource "aws_route" "private_per_subnet_default" {
  for_each = {
    for subnet_name, rt in aws_route_table.private_per_subnet : subnet_name => rt
    if lookup(local.nat_gateway_by_az, aws_subnet.this[subnet_name].availability_zone, null) != null
  }

  route_table_id         = each.value.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = local.nat_gateway_by_az[aws_subnet.this[each.key].availability_zone]
}

resource "aws_route_table_association" "private_per_subnet" {
  for_each = aws_route_table.private_per_subnet

  subnet_id      = aws_subnet.this[each.key].id
  route_table_id = each.value.id
}

resource "aws_network_acl" "this" {
  for_each = var.network_acls

  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = each.value.name })
}

resource "aws_network_acl_rule" "ingress" {
  for_each = { for rule in local.network_acl_ingress_rules : rule.key => rule }

  network_acl_id = aws_network_acl.this[each.value.nacl_key].id
  egress         = false
  rule_number    = each.value.rule.rule_number
  protocol       = each.value.rule.protocol
  rule_action    = each.value.rule.rule_action
  cidr_block     = lookup(each.value.rule, "cidr_block", null)
  ipv6_cidr_block = lookup(each.value.rule, "ipv6_cidr_block", null)
  from_port      = lookup(each.value.rule, "from_port", null)
  to_port        = lookup(each.value.rule, "to_port", null)
  icmp_type      = lookup(each.value.rule, "icmp_type", null)
  icmp_code      = lookup(each.value.rule, "icmp_code", null)
}

resource "aws_network_acl_rule" "egress" {
  for_each = { for rule in local.network_acl_egress_rules : rule.key => rule }

  network_acl_id = aws_network_acl.this[each.value.nacl_key].id
  egress         = true
  rule_number    = each.value.rule.rule_number
  protocol       = each.value.rule.protocol
  rule_action    = each.value.rule.rule_action
  cidr_block     = lookup(each.value.rule, "cidr_block", null)
  ipv6_cidr_block = lookup(each.value.rule, "ipv6_cidr_block", null)
  from_port      = lookup(each.value.rule, "from_port", null)
  to_port        = lookup(each.value.rule, "to_port", null)
  icmp_type      = lookup(each.value.rule, "icmp_type", null)
  icmp_code      = lookup(each.value.rule, "icmp_code", null)
}

resource "aws_network_acl_association" "this" {
  for_each = {
    for assoc in local.network_acl_associations : "${assoc.nacl_key}-${assoc.subnet_name}" => assoc
  }

  subnet_id      = aws_subnet.this[each.value.subnet_name].id
  network_acl_id = aws_network_acl.this[each.value.nacl_key].id
}

resource "aws_route_table" "additional" {
  for_each = var.additional_route_tables

  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = each.value.name })
}

resource "aws_route" "additional" {
  for_each = {
    for rt_key, rt in aws_route_table.additional :
    rt_key => {
      route_table_id = rt.id
      routes         = var.additional_route_tables[rt_key].routes
    }
  }

  route_table_id = each.value.route_table_id

  dynamic "route" {
    for_each = each.value.routes
    content {
      destination_cidr_block          = route.value.destination_cidr_block
      ipv6_destination_cidr_block     = lookup(route.value, "ipv6_destination_cidr_block", null)
      gateway_id                      = lookup(route.value, "gateway_id", null)
      nat_gateway_id                  = lookup(route.value, "nat_gateway_id", null)
      vpc_peering_connection_id       = lookup(route.value, "vpc_peering_connection_id", null)
      transit_gateway_id              = lookup(route.value, "transit_gateway_id", null)
      egress_only_internet_gateway_id = lookup(route.value, "egress_only_internet_gateway_id", null)
    }
  }
}

resource "aws_route_table_association" "additional" {
  for_each = { for assoc in local.additional_route_table_associations : "${assoc.rt_key}-${assoc.subnet_name}" => assoc }

  subnet_id      = aws_subnet.this[each.value.subnet_name].id
  route_table_id = aws_route_table.additional[each.value.rt_key].id
}
