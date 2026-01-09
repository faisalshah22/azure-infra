variable "location" {
  description = "Azure region"
  type        = string
}

variable "vm_size" {
  description = "Size of the VM (Standard_D2s_v3 recommended for Central India - general purpose, better availability)"
  type        = string
}

variable "vm_admin_username" {
  description = "VM administrator username (will be stored in Key Vault)"
  type        = string
}

variable "sql_server_name" {
  description = "Name of the SQL Server"
  type        = string
}

variable "sql_database_name" {
  description = "Name of the SQL Database"
  type        = string
}

variable "sql_admin_login" {
  description = "SQL Server administrator login (will be stored in Key Vault)"
  type        = string
}

variable "key_vault_name" {
  description = "Name of the Key Vault (must be globally unique, 3-24 alphanumeric characters). If not provided, will use kv-prod-secrets with a random suffix."
  type        = string
  default     = null
}

variable "use_existing_key_vault" {
  description = "Set to true if Key Vault already exists and should be imported/referenced instead of created"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
}

