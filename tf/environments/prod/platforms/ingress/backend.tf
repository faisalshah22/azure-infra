terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "tfstatestoragein"
    container_name       = "tfstate"
    key                  = "prod/platforms/ingress/terraform.tfstate"
  }
}

