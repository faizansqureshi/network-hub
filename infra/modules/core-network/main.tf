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

  create = var.create_subnets
  vpc_id = module.vpc.vpc_id

  subnets = merge(
    # Management subnets — public, IGW-routable
    {
      for idx, az in var.availability_zones : "mgmt-${az}" => {
        cidr_block              = var.subnet_cidrs.management[idx]
        availability_zone       = az
        type                    = "public"
        map_public_ip_on_launch = true
      }
    },
    # Trust subnets — isolated, no external routes
    {
      for idx, az in var.availability_zones : "trust-${az}" => {
        cidr_block              = var.subnet_cidrs.trust[idx]
        availability_zone       = az
        type                    = "isolated"
        map_public_ip_on_launch = false
      }
    },
    # GWLBE subnets — private, NAT-routable
    {
      for idx, az in var.availability_zones : "gwlbe-${az}" => {
        cidr_block              = var.subnet_cidrs.gwlbe[idx]
        availability_zone       = az
        type                    = "private"
        map_public_ip_on_launch = false
      }
    },
    # TGW subnets — isolated, extensible routes
    {
      for idx, az in var.availability_zones : "tgw-${az}" => {
        cidr_block              = var.subnet_cidrs.tgw[idx]
        availability_zone       = az
        type                    = "isolated"
        map_public_ip_on_launch = false
      }
    }
  )

  tags = var.tags
}

module "internet_gateway" {
  source = "../services/internet-gateway"

  create = var.create_internet_gateway
  vpc_id = module.vpc.vpc_id
  name   = "${var.name}-igw"

  tags = var.tags
}

module "nat_gateways" {
  source = "../services/nat-gateway"

  create = var.create_nat_gateways

  nat_gateways = {
    for idx, az in var.availability_zones : "nat-${az}" => {
      subnet_id = module.subnets.subnet_ids["mgmt-${az}"]
    }
  }

  tags = var.tags
}

module "route_tables" {
  source = "../services/route-tables"

  create = var.create_route_tables
  vpc_id = module.vpc.vpc_id

  route_tables = {
    mgmt = {
      name = "${var.name}-mgmt-rt"
    }
    trust = {
      name = "${var.name}-trust-rt"
    }
    gwlbe = {
      name = "${var.name}-gwlbe-rt"
    }
    tgw = {
      name = "${var.name}-tgw-rt"
    }
  }

  routes = merge(
    # Management: default route to IGW
    module.internet_gateway.internet_gateway_id != null ? {
      mgmt-igw = {
        route_table_key        = "mgmt"
        destination_cidr_block = "0.0.0.0/0"
        gateway_id             = module.internet_gateway.internet_gateway_id
      }
    } : {},
    # GWLBE: default routes to NAT gateways (one per AZ)
    module.nat_gateways.nat_gateway_ids != {} ? {
      for idx, az in var.availability_zones : "gwlbe-nat-${az}" => {
        route_table_key        = "gwlbe"
        destination_cidr_block = "0.0.0.0/0"
        nat_gateway_id         = module.nat_gateways.nat_gateway_ids["nat-${az}"]
      }
    } : {}
  )

  # Trust subnets → trust RT, GWLBE subnets → gwlbe RT, TGW subnets → tgw RT
  route_table_associations = merge(
    {
      for az in var.availability_zones : "trust-${az}" => {
        route_table_key = "trust"
        subnet_id       = module.subnets.subnet_ids["trust-${az}"]
      }
    },
    {
      for az in var.availability_zones : "gwlbe-${az}" => {
        route_table_key = "gwlbe"
        subnet_id       = module.subnets.subnet_ids["gwlbe-${az}"]
      }
    },
    {
      for az in var.availability_zones : "tgw-${az}" => {
        route_table_key = "tgw"
        subnet_id       = module.subnets.subnet_ids["tgw-${az}"]
      }
    },
    {
      for az in var.availability_zones : "mgmt-${az}" => {
        route_table_key = "mgmt"
        subnet_id       = module.subnets.subnet_ids["mgmt-${az}"]
      }
    }
  )

  tags = var.tags

  depends_on = [module.internet_gateway, module.nat_gateways]
}

# Apply optional TGW routes if provided
module "tgw_routes" {
  source = "../services/route-tables"

  create = var.create_route_tables && length(var.tgw_additional_routes) > 0
  vpc_id = module.vpc.vpc_id

  route_tables = {}

  routes = {
    for idx, route in var.tgw_additional_routes : "tgw-custom-${idx}" => merge(
      {
        route_table_key = "tgw"
      },
      route
    )
  }

  route_table_associations = {}

  tags = var.tags

  depends_on = [module.route_tables]
}


