output "sql_server_fqdn" {
  description = "Fully qualified domain name of the SQL Server"
  value       = azurerm_mssql_server.main.fully_qualified_domain_name
}

output "sql_server_private_fqdn" {
  description = "Private endpoint FQDN for SQL Server (use this for VNet connections)"
  value       = "${var.sql_server_name}.privatelink.database.windows.net"
}

output "sql_server_id" {
  description = "ID of the SQL Server"
  value       = azurerm_mssql_server.main.id
}

output "sql_database_name" {
  description = "Name of the SQL Database"
  value       = azurerm_mssql_database.main.name
}

output "sql_private_endpoint_id" {
  description = "ID of the SQL Private Endpoint"
  value       = azurerm_private_endpoint.sql.id
}
