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
