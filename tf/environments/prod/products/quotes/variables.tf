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


variable "vm_os_disk_storage_account_type" {
  description = "Storage account type for VM OS disk. Use Premium_LRS for better performance and HA."
  type        = string
  default     = "Premium_LRS"
}

variable "sql_database_sku_name" {
  description = "SKU name for the database. Use Standard tier or higher for HA. Examples: S0, S1, S2, S3, P1, P2, etc."
  type        = string
  default     = "S2"
}

variable "sql_database_max_size_gb" {
  description = "Maximum size of the database in GB"
  type        = number
  default     = 50
}

variable "sql_zone_redundant" {
  description = "Enable zone redundancy for the database (requires Premium or Business Critical tier)"
  type        = bool
  default     = false
}

variable "sql_read_scale_enabled" {
  description = "Enable read scale-out for the database (allows read-only replicas)"
  type        = bool
  default     = false
}

variable "sql_geo_backup_enabled" {
  description = "Enable geo-backup for disaster recovery"
  type        = bool
  default     = true
}

variable "sql_short_term_retention_days" {
  description = "Number of days to retain backups (1-35 days)"
  type        = number
  default     = 7
}

variable "vmss_initial_instance_count" {
  description = "Initial number of VM instances in the scale set"
  type        = number
  default     = 2
}

variable "vmss_zones" {
  description = "Availability zones for VMSS (list of zone numbers: [1, 2, 3])"
  type        = list(number)
  default     = [1, 2, 3]
}

variable "vmss_autoscaling_enabled" {
  description = "Enable autoscaling for VMSS"
  type        = bool
  default     = true
}

variable "vmss_autoscale_min_capacity" {
  description = "Minimum number of VM instances"
  type        = number
  default     = 2
}

variable "vmss_autoscale_max_capacity" {
  description = "Maximum number of VM instances"
  type        = number
  default     = 10
}

variable "vmss_autoscale_cpu_threshold_scale_out" {
  description = "CPU threshold percentage to scale out (add more VMs)"
  type        = number
  default     = 70
}

variable "vmss_autoscale_cpu_threshold_scale_in" {
  description = "CPU threshold percentage to scale in (remove VMs)"
  type        = number
  default     = 30
}

variable "key_vault_allowed_ips" {
  description = "List of IP addresses allowed to access Key Vault (for PII protection)"
  type        = list(string)
  default     = []
}

variable "sql_audit_storage_account_endpoint" {
  description = "Storage account endpoint for SQL auditing (PII protection). Format: https://<account>.blob.core.windows.net"
  type        = string
  default     = null
}

variable "sql_audit_storage_account_access_key" {
  description = "Storage account access key for SQL auditing"
  type        = string
  sensitive   = true
  default     = null
}

variable "sql_audit_retention_days" {
  description = "Number of days to retain SQL audit logs (PII protection)"
  type        = number
  default     = 90
}

variable "sql_threat_detection_email_addresses" {
  description = "Email addresses for SQL threat detection alerts (PII protection)"
  type        = list(string)
  default     = []
}

variable "sql_threat_detection_retention_days" {
  description = "Number of days to retain SQL threat detection logs"
  type        = number
  default     = 90
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
}

