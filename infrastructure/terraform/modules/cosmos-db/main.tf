###############################################################################
# Azure Cosmos DB Module
###############################################################################

resource "azurerm_cosmosdb_account" "main" {
  name                      = var.name
  location                  = var.location
  resource_group_name       = var.resource_group_name
  offer_type                = "Standard"
  kind                      = "GlobalDocumentDB"
  enable_automatic_failover = var.environment == "prod" ? true : false
  tags                      = var.tags

  consistency_policy {
    consistency_level       = "Session"
    max_interval_in_seconds = 5
    max_staleness_prefix    = 100
  }

  geo_location {
    location          = var.location
    failover_priority = 0
  }

  backup {
    type                = "Periodic"
    interval_in_minutes = var.environment == "prod" ? 240 : 1440
    retention_in_hours  = var.environment == "prod" ? 720 : 168
    storage_redundancy  = var.environment == "prod" ? "Geo" : "Local"
  }
}

resource "azurerm_cosmosdb_sql_database" "healthcare" {
  name                = "healthcare-ai"
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.main.name
  throughput          = var.environment == "prod" ? 1000 : 400
}

resource "azurerm_cosmosdb_sql_container" "conversations" {
  name                  = "conversations"
  resource_group_name   = var.resource_group_name
  account_name          = azurerm_cosmosdb_account.main.name
  database_name         = azurerm_cosmosdb_sql_database.healthcare.name
  partition_key_path    = "/patientId"
  partition_key_version = 1
  throughput            = var.environment == "prod" ? 400 : 400

  indexing_policy {
    indexing_mode = "consistent"

    included_path {
      path = "/*"
    }

    excluded_path {
      path = "/\"_etag\"/?"
    }
  }
}

resource "azurerm_cosmosdb_sql_container" "assessments" {
  name                  = "assessments"
  resource_group_name   = var.resource_group_name
  account_name          = azurerm_cosmosdb_account.main.name
  database_name         = azurerm_cosmosdb_sql_database.healthcare.name
  partition_key_path    = "/patientId"
  partition_key_version = 1
  throughput            = var.environment == "prod" ? 400 : 400
}
