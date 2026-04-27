resource "aws_eip" "nat" {
  count = var.create ? 1:0  
  domain = "vpc"
  tags   = merge(var.tags, { Name = "nat-eip" })
}

resource "aws_nat_gateway" "this" {
  count = var.create ? 1:0  
  subnet_id     = var.subnet_id
  allocation_id = aws_eip.nat[0].id

  tags = merge(var.tags, { Name = "nat-gateway" })
}
