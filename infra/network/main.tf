terraform {
	required_version = ">= 1.0"

	required_providers {
		aws = {
			source  = "hashicorp/aws"
			version = "~> 5.0"
		}
	}

	backend "s3" {}
}

provider "aws" {
	region = var.aws_region
}

module "core_network" {
	source = "../modules/core-network"

	name                     = var.name
	vpc_cidr                 = var.vpc_cidr
	availability_zones       = var.availability_zones
	subnets                  = var.subnets
	tags                     = var.tags
}
