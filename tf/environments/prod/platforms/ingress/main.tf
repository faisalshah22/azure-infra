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

module "app_gateway" {
  source = "../../../../modules/app-gateway"

  gateway_name        = "agw-prod-ingress"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  subnet_id           = data.terraform_remote_state.connectivity.outputs.app_gateway_subnet_id
  vm_private_ip       = try(data.terraform_remote_state.quotes.outputs.vm_private_ip, var.vm_private_ip)
  tags                = var.tags
}

