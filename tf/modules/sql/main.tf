terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

resource "azurerm_mssql_server" "main" {
  name                         = var.sql_server_name
  resource_group_name          = var.resource_group_name
  location                     = var.location
  version                      = "12.0"
  administrator_login          = var.sql_admin_login
  administrator_login_password = var.sql_admin_password

  public_network_access_enabled = false

  minimum_tls_version = "1.2"

  dynamic "azuread_administrator" {
    for_each = var.azuread_admin_login != null && var.azuread_admin_object_id != null ? [1] : []
    content {
      login_username = var.azuread_admin_login
      object_id      = var.azuread_admin_object_id
      tenant_id      = var.azuread_tenant_id
    }
  }

  identity {
    type = "SystemAssigned"
  }

  tags = merge(var.tags, {
    DataClassification = "PII"
    Compliance         = "Critical"
  })
}

resource "azurerm_mssql_database" "main" {
  name                        = var.sql_database_name
  server_id                   = azurerm_mssql_server.main.id
  collation                   = "SQL_Latin1_General_CP1_CI_AS"
  license_type                = "LicenseIncluded"
  max_size_gb                 = var.database_max_size_gb
  sku_name                    = var.database_sku_name
  zone_redundant              = var.zone_redundant
  read_scale                  = var.read_scale_enabled
  geo_backup_enabled          = var.geo_backup_enabled
  
  short_term_retention_policy {
    retention_days = var.short_term_retention_days
  }

  tags = merge(var.tags, {
    DataClassification = "PII"
    Compliance         = "Critical"
    Encryption         = "TDE-Enabled"
  })
}

resource "azurerm_mssql_server_extended_auditing_policy" "main" {
  count                                  = var.audit_storage_account_endpoint != null ? 1 : 0
  server_id                              = azurerm_mssql_server.main.id
  storage_endpoint                       = var.audit_storage_account_endpoint
  storage_account_access_key             = var.audit_storage_account_access_key
  storage_account_access_key_is_secondary = false
  retention_in_days                      = var.audit_retention_days
  log_monitoring_enabled                 = true
}

resource "azurerm_mssql_server_security_alert_policy" "main" {
  count                     = var.audit_storage_account_endpoint != null ? 1 : 0
  resource_group_name       = var.resource_group_name
  server_name               = azurerm_mssql_server.main.name
  state                     = "Enabled"
  email_account_admins      = true
  email_addresses           = var.threat_detection_email_addresses
  disabled_alerts           = []
  retention_days            = var.threat_detection_retention_days
  storage_account_access_key = var.audit_storage_account_access_key
  storage_endpoint          = var.audit_storage_account_endpoint
}

resource "azurerm_private_dns_zone" "sql" {
  name                = "privatelink.database.windows.net"
  resource_group_name = var.resource_group_name

  tags = merge(var.tags, {
    DataClassification = "PII"
    Compliance         = "Critical"
  })
}

resource "azurerm_private_dns_zone_virtual_network_link" "sql" {
  name                  = "${var.sql_server_name}-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.sql.name
  virtual_network_id    = var.vnet_id
  registration_enabled  = false

  tags = var.tags
}

resource "azurerm_private_endpoint" "sql" {
  name                = "${var.sql_server_name}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.sql_server_name}-psc"
    private_connection_resource_id = azurerm_mssql_server.main.id
    subresource_names              = ["sqlServer"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "${var.sql_server_name}-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.sql.id]
  }

  tags = merge(var.tags, {
    DataClassification = "PII"
    Compliance         = "Critical"
  })
}
