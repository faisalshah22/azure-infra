output "vnet_id" {
  description = "ID of the virtual network"
  value       = module.vpc.vnet_id
}

output "vnet_name" {
  description = "Name of the virtual network"
  value       = module.vpc.vnet_name
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = module.vpc.public_subnet_id
}

output "private_subnet_id" {
  description = "ID of the private subnet"
  value       = module.vpc.private_subnet_id
}

output "resource_group_name" {
  description = "Name of the resource group"
  value       = data.azurerm_resource_group.main.name
}

output "vnet_address_space" {
  description = "Address space of the virtual network"
  value       = var.vnet_address_space
}

output "app_gateway_subnet_id" {
  description = "ID of the Application Gateway subnet"
  value       = module.vpc.app_gateway_subnet_id
}

output "app_gateway_subnet_cidr" {
  description = "CIDR block of the Application Gateway subnet"
  value       = var.app_gateway_subnet_cidr
}

output "bastion_id" {
  description = "ID of the Bastion host"
  value       = try(module.bastion[0].bastion_id, null)
}

output "bastion_host_name" {
  description = "Name of the Bastion host"
  value       = try(module.bastion[0].bastion_host_name, null)
}

