location          = "centralindia"
vm_size           = "Standard_D2s_v3"
vm_admin_username = "azureadmin"
sql_server_name   = "sql-prod-quotes"
sql_database_name = "quotesdb"
sql_admin_login   = "sqladmin"

vm_os_disk_storage_account_type = "Premium_LRS"

vmss_initial_instance_count          = 2
vmss_zones                           = []
vmss_autoscaling_enabled             = true
vmss_autoscale_min_capacity          = 2
vmss_autoscale_max_capacity          = 10
vmss_autoscale_cpu_threshold_scale_out = 70
vmss_autoscale_cpu_threshold_scale_in  = 30
sql_database_sku_name            = "S2"
sql_database_max_size_gb         = 50
sql_zone_redundant               = false
sql_read_scale_enabled           = false
sql_geo_backup_enabled           = true
sql_short_term_retention_days    = 7

key_vault_name        = null
use_existing_key_vault = false

key_vault_allowed_ips = ["157.48.1.236"]

sql_audit_retention_days = 90
sql_threat_detection_email_addresses = []
sql_threat_detection_retention_days = 90

tags = {
  Environment        = "prod"
  ManagedBy          = "Terraform"
  DataClassification = "PII"
  Compliance         = "Critical"
}
