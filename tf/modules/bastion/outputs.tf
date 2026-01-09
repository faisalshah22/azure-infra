output "bastion_id" {
  description = "ID of the Bastion host"
  value       = azurerm_bastion_host.main.id
}

output "bastion_host_name" {
  description = "Name of the Bastion host"
  value       = azurerm_bastion_host.main.name
}

