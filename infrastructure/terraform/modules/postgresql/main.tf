###############################################################################
# Azure Database for PostgreSQL Flexible Server Module
###############################################################################

resource "random_password" "admin" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "azurerm_postgresql_flexible_server" "main" {
  name                   = var.name
  resource_group_name    = var.resource_group_name
  location               = var.location
  version                = "15"
  administrator_login    = "healthcareadmin"
  administrator_password = random_password.admin.result
  zone                   = "1"
  storage_mb             = var.environment == "prod" ? 131072 : 32768
  tags                   = var.tags

  sku_name = var.environment == "prod" ? "GP_Standard_D4s_v3" : "B_Standard_B2s"

  backup_retention_days        = var.environment == "prod" ? 35 : 7
  geo_redundant_backup_enabled = var.environment == "prod" ? true : false

  high_availability {
    mode                      = var.environment == "prod" ? "ZoneRedundant" : "Disabled"
    standby_availability_zone = var.environment == "prod" ? "2" : null
  }
}

resource "azurerm_postgresql_flexible_server_database" "healthcare" {
  name      = "healthcare_ai"
  server_id = azurerm_postgresql_flexible_server.main.id
  collation = "en_US.utf8"
  charset   = "utf8"
}

resource "azurerm_postgresql_flexible_server_database" "audit" {
  name      = "healthcare_audit"
  server_id = azurerm_postgresql_flexible_server.main.id
  collation = "en_US.utf8"
  charset   = "utf8"
}

# Store password in Key Vault
resource "azurerm_key_vault_secret" "pg_password" {
  count        = var.key_vault_id != "" ? 1 : 0
  name         = "postgresql-admin-password"
  value        = random_password.admin.result
  key_vault_id = var.key_vault_id
}
