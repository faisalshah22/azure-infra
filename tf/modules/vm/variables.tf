variable "vm_name" {
  description = "Name of the virtual machine"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "subnet_id" {
  description = "ID of the subnet for the VM"
  type        = string
}

variable "private_ip_address" {
  description = "Private IP address for the VM (optional - if not provided, Azure will assign dynamically)"
  type        = string
  default     = null
}

variable "vm_size" {
  description = "Size of the VM"
  type        = string
  default     = "Standard_B1s"
}

variable "admin_username" {
  description = "Admin username for the VM (fetched from Key Vault)"
  type        = string
}

variable "admin_password" {
  description = "Admin password for VM access (fetched from Key Vault)"
  type        = string
  sensitive   = true
}

variable "cloud_init_script" {
  description = "Cloud-init script for VM initialization"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

