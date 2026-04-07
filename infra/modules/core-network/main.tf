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
}


