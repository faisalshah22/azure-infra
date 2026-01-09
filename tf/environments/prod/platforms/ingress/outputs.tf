output "gateway_id" {
  description = "ID of the Application Gateway"
  value       = module.app_gateway.gateway_id
}

output "public_ip_address" {
  description = "Public IP address of the Application Gateway"
  value       = module.app_gateway.public_ip_address
}

