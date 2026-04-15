###############################################################################
# Azure OpenAI Service Module
###############################################################################

resource "azurerm_cognitive_account" "openai" {
  name                  = var.name
  location              = var.location
  resource_group_name   = var.resource_group_name
  kind                  = "OpenAI"
  sku_name              = "S0"
  custom_subdomain_name = var.name
  tags                  = var.tags

  network_acls {
    default_action = var.environment == "prod" ? "Deny" : "Allow"
  }
}

resource "azurerm_cognitive_deployment" "gpt4" {
  name                 = "gpt-4"
  cognitive_account_id = azurerm_cognitive_account.openai.id

  model {
    format  = "OpenAI"
    name    = "gpt-4"
    version = "0613"
  }

  scale {
    type     = "Standard"
    capacity = var.environment == "prod" ? 120 : 40
  }
}

resource "azurerm_cognitive_deployment" "gpt35" {
  name                 = "gpt-35-turbo"
  cognitive_account_id = azurerm_cognitive_account.openai.id

  model {
    format  = "OpenAI"
    name    = "gpt-35-turbo"
    version = "0613"
  }

  scale {
    type     = "Standard"
    capacity = var.environment == "prod" ? 120 : 60
  }
}

# Store API key in Key Vault
resource "azurerm_key_vault_secret" "openai_key" {
  count        = var.key_vault_id != "" ? 1 : 0
  name         = "azure-openai-key"
  value        = azurerm_cognitive_account.openai.primary_access_key
  key_vault_id = var.key_vault_id
}
