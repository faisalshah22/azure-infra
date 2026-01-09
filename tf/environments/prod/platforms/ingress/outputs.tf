output "lb_id" {
  description = "ID of the Load Balancer"
  value       = module.load_balancer.lb_id
}

output "public_ip_address" {
  description = "Public IP address of the Load Balancer"
  value       = module.load_balancer.public_ip_address
}

output "backend_pool_id" {
  description = "ID of the backend address pool for VMSS"
  value       = module.load_balancer.backend_pool_id
}

