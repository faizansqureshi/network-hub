resource "aws_eip" "nat" {
  for_each = var.create ? var.nat_gateways : {}

  domain = "vpc"
  tags   = merge(var.tags, { Name = "${each.key}-eip" })
}

resource "aws_nat_gateway" "this" {
  for_each = var.create ? var.nat_gateways : {}

  subnet_id     = each.value.subnet_id
  allocation_id = aws_eip.nat[each.key].id

  tags = merge(var.tags, { Name = each.key })
}
