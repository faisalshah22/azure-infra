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

data "terraform_remote_state" "connectivity" {
  backend = "azurerm"
  config = {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "tfstatestoragein"
    container_name       = "tfstate"
    key                  = "prod/landing-zones/connectivity/terraform.tfstate"
  }
}

data "terraform_remote_state" "quotes" {
  backend = "azurerm"
  config = {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "tfstatestoragein"
    container_name       = "tfstate"
    key                  = "prod/products/quotes/terraform.tfstate"
  }
}

data "azurerm_resource_group" "main" {
  name = "tfstate-rg"
}

data "azurerm_virtual_network" "main" {
  name                = "vnet-prod-connectivity"
  resource_group_name = data.azurerm_resource_group.main.name
}

module "load_balancer" {
  source = "../../../../modules/load-balancer"

  lb_name             = "lb-prod-ingress"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  vnet_id             = data.azurerm_virtual_network.main.id
  zones               = var.lb_zones
  tags                 = var.tags
}

