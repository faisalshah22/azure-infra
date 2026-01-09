output "vmss_id" {
  description = "ID of the Virtual Machine Scale Set"
  value       = azurerm_linux_virtual_machine_scale_set.main.id
}

output "vmss_name" {
  description = "Name of the Virtual Machine Scale Set"
  value       = azurerm_linux_virtual_machine_scale_set.main.name
}

output "vmss_principal_id" {
  description = "Principal ID of the VMSS (for Application Gateway backend integration)"
  value       = azurerm_linux_virtual_machine_scale_set.main.id
}

output "vmss_resource_group_name" {
  description = "Resource group name of the VMSS"
  value       = var.resource_group_name
}
