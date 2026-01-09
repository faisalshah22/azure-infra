terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

data "azurerm_resource_group" "main" {
  name = "tfstate-rg"
}

module "vpc" {
  source = "../../../../modules/vpc"

  vnet_name               = "vnet-prod-connectivity"
  vnet_address_space      = var.vnet_address_space
  public_subnet_cidr      = var.public_subnet_cidr
  private_subnet_cidr     = var.private_subnet_cidr
  app_gateway_subnet_cidr = var.app_gateway_subnet_cidr
  bastion_subnet_cidr     = var.bastion_subnet_cidr
  location                = var.location
  resource_group_name     = data.azurerm_resource_group.main.name
  tags                    = var.tags
}

module "bastion" {
  count  = var.bastion_subnet_cidr != "" ? 1 : 0
  source = "../../../../modules/bastion"

  bastion_name        = "bastion-prod-connectivity"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  subnet_id           = module.vpc.bastion_subnet_id
  tags                = var.tags
}

