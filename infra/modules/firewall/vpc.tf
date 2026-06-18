# Firewall network infrastructure using modular components
# Architecture: 3 AZs, 4 subnet types per AZ with independent route tables

module "vpc" {
  source = "../services/vpc"

  name       = var.name
  cidr_block = var.vpc_cidr

  tags = var.tags
}

module "subnets" {
  source = "../services/subnets"

  create = true
  vpc_id = module.vpc.vpc_id

  subnets = var.subnets

  tags = var.tags
} # multiple Subnets for each AZ and type

module "internet-gateway" {
  source = "../services/internet-gateway"

  vpc_id = module.vpc.vpc_id
  name   = "internet-gateway"
  tags   = var.tags
} #ig deploy on VPC 

module "nat-gateway" {
  for_each = var.nat_gateway_subnets # Create a single NAT gateway for simplicity
  source   = "../services/nat-gateway"

  create    = true
  subnet_id = module.subnets.ids[each.value] # Place NAT gateway in the configured subnet (e.g., mgmt)
  tags      = var.tags

} # deploy nat gateway for each subnet

module "network-acl" {
  for_each = module.subnets.subnet_ids_by_segment
  source   = "../services/network-acl"

  create = true
  vpc_id = module.vpc.vpc_id
  name   = "${each.key}-nacl"

  nacl_associations = {
    for subnet_name, subnet_id in each.value : subnet_name => {
      subnet_id = subnet_id
    }
  } # associate all subnets in the segment with the segment NACL
}


module "route-tables" {
  for_each = module.subnets.subnet_ids_by_segment
  source   = "../services/route-tables"

  create = true
  vpc_id = module.vpc.vpc_id
  name   = "${each.key}-rt"

  route_table_associations = {
    for subnet_name, subnet_id in each.value : subnet_name => {
      subnet_id = subnet_id
    }
  }
}


#after create route tables

