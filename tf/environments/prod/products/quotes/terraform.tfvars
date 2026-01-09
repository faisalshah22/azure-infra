location          = "centralindia"
vm_size           = "Standard_D2s_v3"
vm_admin_username = "azureadmin"
sql_server_name   = "sql-prod-quotes"
sql_database_name = "quotesdb"
sql_admin_login   = "sqladmin"

key_vault_name        = null
use_existing_key_vault = false

tags = {
  Environment = "prod"
  ManagedBy   = "Terraform"
}
