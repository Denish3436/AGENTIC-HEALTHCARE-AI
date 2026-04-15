###############################################################################
# Azure Cache for Redis Module
###############################################################################

resource "azurerm_redis_cache" "main" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  capacity            = var.environment == "prod" ? 1 : 0
  family              = var.environment == "prod" ? "P" : "C"
  sku_name            = var.environment == "prod" ? "Premium" : "Standard"
  enable_non_ssl_port = false
  minimum_tls_version = "1.2"
  tags                = var.tags

  redis_configuration {
    maxmemory_reserved = var.environment == "prod" ? 256 : 50
    maxmemory_policy   = "allkeys-lru"
  }
}
