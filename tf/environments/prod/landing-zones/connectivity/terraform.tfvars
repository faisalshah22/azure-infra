location                = "centralindia"
vnet_address_space      = "10.0.0.0/16"
public_subnet_cidr      = "10.0.1.0/24"
private_subnet_cidr     = "10.0.2.0/24"
app_gateway_subnet_cidr = "10.0.3.0/24"
bastion_subnet_cidr     = "10.0.4.0/26"

tags = {
  Environment = "prod"
  ManagedBy   = "Terraform"
}
