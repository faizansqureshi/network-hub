resource "aws_route_table" "this" {
  for_each = var.create ? var.route_tables : {}

  vpc_id = var.vpc_id
  tags   = merge(var.tags, { Name = each.value.name })
}

resource "aws_route" "this" {
  for_each = {
    for rt_key, route in var.create ? var.routes : {} : rt_key => route
  }

  route_table_id              = aws_route_table.this[each.value.route_table_key].id
  destination_cidr_block      = try(each.value.destination_cidr_block, null)
  destination_ipv6_cidr_block = try(each.value.destination_ipv6_cidr_block, null)
  gateway_id                  = try(each.value.gateway_id, null)
  nat_gateway_id              = try(each.value.nat_gateway_id, null)
  vpc_peering_connection_id   = try(each.value.vpc_peering_connection_id, null)
  transit_gateway_id          = try(each.value.transit_gateway_id, null)
  egress_only_gateway_id      = try(each.value.egress_only_gateway_id, null)
}

resource "aws_route_table_association" "this" {
  for_each = var.create ? var.route_table_associations : {}

  subnet_id      = each.value.subnet_id
  route_table_id = aws_route_table.this[each.value.route_table_key].id
}
