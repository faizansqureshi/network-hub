// This module creates an AWS VPC with multiple subnets, route tables, NAT gateways, an Internet Gateway, and security groups.
//
// Usage example (in a root module):
//
// module "vpc" {
//   source = "./modules/services/vpc"
//
//   name       = "example"
//   cidr_block = "10.0.0.0/16"
//
//   subnets = [
//     {
//       name                    = "public-1"
//       cidr                    = "10.0.1.0/24"
//       availability_zone       = "eu-west-1a"
//       type                    = "public"
//       map_public_ip_on_launch = true
//     }
//     {
//       name                    = "private-1"
//       cidr                    = "10.0.2.0/24"
//       availability_zone       = "eu-west-1a"
//       type                    = "private"
//       map_public_ip_on_launch = false
//     }
//   ]
//
//   security_groups = [
//     {
//       name        = "web-sg"
//       description = "Allow web traffic"
//       ingress = [
//         {
//           from_port   = 80
//           to_port     = 80
//           protocol    = "tcp"
//           cidr_blocks = ["0.0.0.0/0"]
//         }
//       ]
//       egress = [
//         {
//           from_port   = 0
//           to_port     = 0
//           protocol    = "-1"
//           cidr_blocks = ["0.0.0.0/0"]
//         }
//       ]
//     }
//   ]
// }

locals {
  subnet_map = { for s in var.subnets : s.name => s }

  public_subnet_names  = [for s in var.subnets : s.name if lower(s.type) == "public"]
  private_subnet_names = [for s in var.subnets : s.name if lower(s.type) == "private"]
  isolated_subnet_names = [for s in var.subnets : s.name if lower(s.type) == "isolated"]
}

resource "aws_vpc" "this" {
  cidr_block           = var.cidr_block
  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames

  tags = merge(var.tags, { Name = var.name })
}

resource "aws_internet_gateway" "this" {
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
    Name = each.value.name
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
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
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
  count = var.create_single_private_route_table && length(local.private_subnet_names) > 0 && var.enable_nat_gateway ? 1 : 0

  route_table_id         = aws_route_table.private[0].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = length(aws_nat_gateway.this) > 0 ? aws_nat_gateway.this[0].id : null
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
  for_each = aws_route_table.private_per_subnet

  route_table_id         = each.value.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = lookup(local.nat_gateway_by_az, aws_subnet.this[each.key].availability_zone, null)
}

resource "aws_route_table_association" "private_per_subnet" {
  for_each = aws_route_table.private_per_subnet

  subnet_id      = aws_subnet.this[each.key].id
  route_table_id = each.value.id
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

resource "aws_security_group" "this" {
  for_each = { for sg in var.security_groups : sg.name => sg }

  name        = each.value.name
  description = each.value.description
  vpc_id      = aws_vpc.this.id
  tags        = merge(var.tags, each.value.tags)

  dynamic "ingress" {
    for_each = each.value.ingress
    content {
      from_port        = ingress.value.from_port
      to_port          = ingress.value.to_port
      protocol         = ingress.value.protocol
      cidr_blocks      = lookup(ingress.value, "cidr_blocks", [])
      ipv6_cidr_blocks = lookup(ingress.value, "ipv6_cidr_blocks", [])
      security_groups  = lookup(ingress.value, "security_groups", [])
      prefix_list_ids  = lookup(ingress.value, "prefix_list_ids", [])
      self             = lookup(ingress.value, "self", false)
    }
  }

  dynamic "egress" {
    for_each = each.value.egress
    content {
      from_port        = egress.value.from_port
      to_port          = egress.value.to_port
      protocol         = egress.value.protocol
      cidr_blocks      = lookup(egress.value, "cidr_blocks", [])
      ipv6_cidr_blocks = lookup(egress.value, "ipv6_cidr_blocks", [])
      security_groups  = lookup(egress.value, "security_groups", [])
      prefix_list_ids  = lookup(egress.value, "prefix_list_ids", [])
      self             = lookup(egress.value, "self", false)
    }
  }
}
