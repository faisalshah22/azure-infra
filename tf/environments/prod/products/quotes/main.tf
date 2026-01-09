terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
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

data "terraform_remote_state" "ingress" {
  backend = "azurerm"
  config = {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "tfstatestoragein"
    container_name       = "tfstate"
    key                  = "prod/platforms/ingress/terraform.tfstate"
  }
}

data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "main" {
  name = "tfstate-rg"
}

resource "random_password" "vm_admin_password" {
  length  = 16
  special = true
}

resource "random_password" "sql_admin_password" {
  length  = 16
  special = true
}

resource "random_id" "kv_suffix" {
  count       = var.key_vault_name == null ? 1 : 0
  byte_length = 4
}

locals {
  key_vault_name = var.key_vault_name != null ? var.key_vault_name : "kv-prod-secrets-${substr(random_id.kv_suffix[0].hex, 0, 6)}"
}

data "azurerm_key_vault" "existing" {
  count               = var.use_existing_key_vault ? 1 : 0
  name                = local.key_vault_name
  resource_group_name = data.azurerm_resource_group.main.name
}

resource "azurerm_key_vault" "secrets" {
  count                      = var.use_existing_key_vault ? 0 : 1
  name                       = local.key_vault_name
  location                   = var.location
  resource_group_name        = data.azurerm_resource_group.main.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  
      soft_delete_retention_days = 90

      purge_protection_enabled   = true

      network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
    ip_rules       = var.key_vault_allowed_ips
    virtual_network_subnet_ids = [
      data.terraform_remote_state.connectivity.outputs.private_subnet_id
    ]
  }

      lifecycle {
    ignore_changes = [soft_delete_retention_days]
  }

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get", "List"
    ]

    secret_permissions = [
      "Get", "List", "Set", "Delete", "Recover", "Backup", "Restore"
    ]

    storage_permissions = [
      "Get", "List"
    ]
  }

  tags = var.tags
}

locals {
  key_vault_id = var.use_existing_key_vault ? data.azurerm_key_vault.existing[0].id : azurerm_key_vault.secrets[0].id
}

resource "azurerm_key_vault_secret" "vm_admin_username" {
  name         = "vm-admin-username"
  value        = var.vm_admin_username
  key_vault_id = local.key_vault_id

  tags = var.tags
}

resource "azurerm_key_vault_secret" "vm_admin_password" {
  name         = "vm-admin-password"
  value        = random_password.vm_admin_password.result
  key_vault_id = local.key_vault_id

  tags = var.tags
}

resource "azurerm_key_vault_secret" "sql_admin_login" {
  name         = "sql-admin-login"
  value        = var.sql_admin_login
  key_vault_id = local.key_vault_id

  tags = var.tags
}

resource "azurerm_key_vault_secret" "sql_admin_password" {
  name         = "sql-admin-password"
  value        = random_password.sql_admin_password.result
  key_vault_id = local.key_vault_id

  tags = var.tags
}

module "nsg" {
  source = "../../../../modules/nsg"

  nsg_name                = "nsg-prod-quotes"
  location                = var.location
  resource_group_name     = data.azurerm_resource_group.main.name
  subnet_id               = data.terraform_remote_state.connectivity.outputs.private_subnet_id
  app_gateway_subnet_cidr = data.terraform_remote_state.connectivity.outputs.app_gateway_subnet_cidr
  tags                    = var.tags
}

module "sql" {
  source = "../../../../modules/sql"

  sql_server_name                    = var.sql_server_name
  sql_database_name                  = var.sql_database_name
  location                           = var.location
  resource_group_name                = data.azurerm_resource_group.main.name
  sql_admin_login                    = azurerm_key_vault_secret.sql_admin_login.value
  sql_admin_password                 = azurerm_key_vault_secret.sql_admin_password.value
  vnet_id                            = data.terraform_remote_state.connectivity.outputs.vnet_id
  private_endpoint_subnet_id         = data.terraform_remote_state.connectivity.outputs.private_subnet_id
  database_sku_name                  = var.sql_database_sku_name
  database_max_size_gb               = var.sql_database_max_size_gb
  zone_redundant                     = var.sql_zone_redundant
  read_scale_enabled                 = var.sql_read_scale_enabled
  geo_backup_enabled                 = var.sql_geo_backup_enabled
  short_term_retention_days          = var.sql_short_term_retention_days
  audit_storage_account_endpoint     = var.sql_audit_storage_account_endpoint
  audit_storage_account_access_key   = var.sql_audit_storage_account_access_key
  audit_retention_days               = var.sql_audit_retention_days
  threat_detection_email_addresses   = var.sql_threat_detection_email_addresses
  threat_detection_retention_days    = var.sql_threat_detection_retention_days
  tags                               = var.tags
}

locals {
  app_py_content_b64       = base64encode(file("${path.module}/../../../../../app/app.py"))
  requirements_content_b64  = base64encode(file("${path.module}/../../../../../app/requirements.txt"))
  init_db_content_b64       = base64encode(file("${path.module}/../../../../../app/init-db.sql"))
  
  cloud_init_script = templatefile("${path.module}/cloud-init.yaml", {
    sql_server_fqdn      = module.sql.sql_server_fqdn
    sql_database_name   = module.sql.sql_database_name
    sql_admin_login     = azurerm_key_vault_secret.sql_admin_login.value
    sql_admin_password   = azurerm_key_vault_secret.sql_admin_password.value
    app_py_content_b64       = local.app_py_content_b64
    requirements_content_b64 = local.requirements_content_b64
    init_db_content_b64      = local.init_db_content_b64
  })
}

module "vmss" {
  source = "../../../../modules/vmss"

  vmss_name                        = "vmss-prod-quotes"
  location                         = var.location
  resource_group_name              = data.azurerm_resource_group.main.name
  subnet_id                        = data.terraform_remote_state.connectivity.outputs.private_subnet_id
  vm_size                          = var.vm_size
  initial_instance_count          = var.vmss_initial_instance_count
  zones                            = var.vmss_zones
  admin_username                   = azurerm_key_vault_secret.vm_admin_username.value
  admin_password                   = azurerm_key_vault_secret.vm_admin_password.value
  cloud_init_script                = local.cloud_init_script
  os_disk_storage_account_type     = var.vm_os_disk_storage_account_type
  load_balancer_backend_pool_ids   = try([data.terraform_remote_state.ingress.outputs.backend_pool_id], [])
  autoscaling_enabled              = var.vmss_autoscaling_enabled
  autoscale_min_capacity           = var.vmss_autoscale_min_capacity
  autoscale_max_capacity           = var.vmss_autoscale_max_capacity
  autoscale_cpu_threshold_scale_out = var.vmss_autoscale_cpu_threshold_scale_out
  autoscale_cpu_threshold_scale_in  = var.vmss_autoscale_cpu_threshold_scale_in
  tags                             = var.tags
}

module "monitoring" {
  source = "../../../../modules/monitoring"

  workspace_name      = "law-prod-quotes"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  tags                = var.tags
}

