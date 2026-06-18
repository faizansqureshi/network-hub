resource "aws_subnet" "this" {
  for_each = var.create ? var.subnets : {}

  vpc_id                  = var.vpc_id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = each.value.map_public_ip_on_launch

  tags = merge(var.tags, {
    Name     = each.key
    Segment  = lower(try(each.value.segment, split("-", each.key)[0]))
    segtment = lower(try(each.value.segment, split("-", each.key)[0]))
  })
}
