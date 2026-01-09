output "vmss_id" {
  description = "ID of the Virtual Machine Scale Set"
  value       = module.vmss.vmss_id
}

output "vmss_name" {
  description = "Name of the Virtual Machine Scale Set"
  value       = module.vmss.vmss_name
}

output "sql_server_fqdn" {
  description = "Fully qualified domain name of the SQL Server"
  value       = module.sql.sql_server_fqdn
}

output "sql_database_name" {
  description = "Name of the SQL Database"
  value       = module.sql.sql_database_name
}

