variable "sql_server_name" {
  description = "Name of the SQL Server"
  type        = string
}

variable "sql_database_name" {
  description = "Name of the SQL Database"
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

variable "sql_admin_login" {
  description = "SQL Server administrator login"
  type        = string
}

variable "sql_admin_password" {
  description = "SQL Server administrator password"
  type        = string
  sensitive   = true
}

variable "subnet_id" {
  description = "Subnet ID for VM access (deprecated - using private endpoint now)"
  type        = string
  default     = null
}

variable "vnet_id" {
  description = "Virtual Network ID for private DNS zone link"
  type        = string
}

variable "private_endpoint_subnet_id" {
  description = "Subnet ID for Private Endpoint (SQL accessible only from this subnet)"
  type        = string
}

variable "database_sku_name" {
  description = "SKU name for the database. Use Standard tier or higher for HA. Examples: S0, S1, S2, S3, P1, P2, etc."
  type        = string
  default     = "S2"
}

variable "database_max_size_gb" {
  description = "Maximum size of the database in GB"
  type        = number
  default     = 50
}

variable "zone_redundant" {
  description = "Enable zone redundancy for the database (requires Premium or Business Critical tier)"
  type        = bool
  default     = false
}

variable "read_scale_enabled" {
  description = "Enable read scale-out for the database (allows read-only replicas)"
  type        = bool
  default     = false
}

variable "geo_backup_enabled" {
  description = "Enable geo-backup for disaster recovery"
  type        = bool
  default     = true
}

variable "short_term_retention_days" {
  description = "Number of days to retain backups (1-35 days)"
  type        = number
  default     = 7
}

variable "azuread_admin_login" {
  description = "Azure AD administrator login for SQL Server (for PII protection)"
  type        = string
  default     = null
}

variable "azuread_admin_object_id" {
  description = "Azure AD administrator object ID"
  type        = string
  default     = null
}

variable "azuread_tenant_id" {
  description = "Azure AD tenant ID"
  type        = string
  default     = null
}

variable "audit_storage_account_endpoint" {
  description = "Storage account endpoint for SQL auditing (PII protection)"
  type        = string
  default     = null
}

variable "audit_storage_account_access_key" {
  description = "Storage account access key for SQL auditing"
  type        = string
  sensitive   = true
  default     = null
}

variable "audit_retention_days" {
  description = "Number of days to retain audit logs (PII protection)"
  type        = number
  default     = 90
}

variable "threat_detection_email_addresses" {
  description = "Email addresses for threat detection alerts (PII protection)"
  type        = list(string)
  default     = []
}

variable "threat_detection_retention_days" {
  description = "Number of days to retain threat detection logs"
  type        = number
  default     = 90
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

